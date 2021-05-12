//
//  SingleImageARCardView.swift
//  
//
//  Created by O'Brien, Patrick on 5/11/21.
//

import SwiftUI

/**
 Content View which displays the card and marker views after a discovery flow for a single Image in the scene after the discoveryFlowHasFinished has been set to True. Only displays the views which are set to isVisible. Cards and Markers are initially set to isVisible.
 
 ## Usage
 ```
 // Constructor for Default ScanningView, CardView, and MarkerView
 SingleImageARCardView(arModel: arModel,
                       image: Image("qrImage"),
                       cardAction: { id in
                             // set the card action for id corresponding to the CardItemModel
                             print(id)
                       })
         .onAppear(perform: loadData)
 
 
 // Constructors with viewbuilders for each combination of Views
 // Use the CarouselOptions View Modifier to adjust the behavior of the Carousel
 SingleImageARCardView(arModel: arModel,
                       scanLabel: { anchorPosition in
                           CustomScanView(image: Image("qrImage"), position: anchorPosition)
                       },
                       cardLabel: { cardmodel, isSelected in
                           CustomCardView(model: cardmodel, isSelected: isSelected)
                       },
                       markerLabel: { state, icon  in
                           CustomMarkerView(state: state)
                       })
         .carouselOptions(CarouselOptions(itemSpacing: 5, carouselHeight: 200, alignment: .center))
         .onAppear(perform: loadData)
 
 
 func loadData() {
     let cardItems = Tests.cardItems
     let strategy = RealityComposerStrategy(cardContents: cardItems, rcFile: "ExampleRC", rcScene: "ExampleScene")
     arModel.load(loadingStrategy: strategy)
 }
 ```
 */

public struct SingleImageARCardView<Scan: View, Card: View, Marker: View, CardItem>: View where CardItem : CardItemModel {
    
    /// arModel
    @ObservedObject public var arModel: ARAnnotationViewModel<CardItem>
    
    /// View Builder for a custom Scanning View. After the Image/Object has been discovered there is a 3 second delay until the ContentView displays Markers and Cards
    public let scanLabel: (Binding<CGPoint?>) -> Scan
    
    /// View Builder for a custom CardView
    public let cardLabel: (CardItem, Bool) -> Card
    
    /// ViewBuilder for a custom MarkerView
    public let markerLabel: (MarkerControl.State, Image?) -> Marker
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                @ViewBuilder scanLabel: @escaping (Binding<CGPoint?>) -> Scan,
                @ViewBuilder cardLabel: @escaping (CardItem, Bool) -> Card,
                @ViewBuilder markerLabel: @escaping (MarkerControl.State, Image?) -> Marker) {
        
        self.arModel = arModel
        self.scanLabel = scanLabel
        self.cardLabel = cardLabel
        self.markerLabel = markerLabel
    }
    
    public var body: some View {
        ZStack {
            ARContainer(arState: arModel)
            
            if arModel.discoveryFlowHasFinished {
                
                ARAnnotationContentView($arModel.annotations,
                                        currentAnnotation: $arModel.currentAnnotation,
                                        cardLabel: cardLabel,
                                        markerLabel: markerLabel)
                
            } else {
                scanLabel($arModel.anchorPosition)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(DismissButton(onDismiss: onDismiss).opacity(Double(0.8)), alignment: .topLeading)
    }
    
    private func onDismiss() {
        arModel.cleanUpSession()
    }
    
    private struct DismissButton: View {
        let onDismiss: (() -> Void)?
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        
        var body: some View {
            Button(action: {
                onDismiss?()
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "arrow.backward")
                    .frame(width: 44, height: 44)
                    .font(.system(size: 19))
                    .foregroundColor(Color(red: 250/255, green: 250/255, blue: 250/255))
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color.black.opacity(0.6))
                    )
            })
            .padding(.leading, 16)
        }
    }
}

extension SingleImageARCardView where Scan == ARScanView,
                                      Card == CardView<Text,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       _ConditionalContent<ImagePreview, DefaultIcon>,
                                                       _ConditionalContent<Text, EmptyView>, CardItem>,
                                      Marker == MarkerView {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                image: Image,
                cardAction: ((CardItem.ID) -> Void)?)
    {
        self.init(arModel: arModel,
                  scanLabel: { anchorPosition in ARScanView(image: image, anchorPosition: anchorPosition) },
                  cardLabel: { cardItem, isSelected in CardView(model: cardItem, isSelected: isSelected, action: cardAction) },
                  markerLabel: { state, icon in MarkerView(state: state, icon: icon) })
    }
}

extension SingleImageARCardView where Scan == ARScanView,
                                      Card == CardView<Text,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       _ConditionalContent<ImagePreview, DefaultIcon>,
                                                       _ConditionalContent<Text, EmptyView>, CardItem> {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                image: Image,
                @ViewBuilder markerLabel: @escaping (MarkerControl.State, Image?) -> Marker,
                cardAction: ((CardItem.ID) -> Void)?)
    {
        self.init(arModel: arModel,
                  scanLabel: { anchorPosition in ARScanView(image: image, anchorPosition: anchorPosition) },
                  cardLabel: { cardItem, isSelected in CardView(model: cardItem, isSelected: isSelected, action: cardAction) },
                  markerLabel: markerLabel)
    }
}

extension SingleImageARCardView where Scan == ARScanView,
                                      Marker == MarkerView {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                image: Image,
                @ViewBuilder cardLabel: @escaping (CardItem, Bool) -> Card)
    {
        self.init(arModel: arModel,
                  scanLabel: { anchorPosition in ARScanView(image: image, anchorPosition: anchorPosition) },
                  cardLabel: cardLabel,
                  markerLabel: { state, icon in MarkerView(state: state, icon: icon) })
    }
}

extension SingleImageARCardView where Card == CardView<Text,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       _ConditionalContent<ImagePreview, DefaultIcon>,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       CardItem>,
                                      Marker == MarkerView {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                @ViewBuilder scanLabel: @escaping (Binding<CGPoint?>) -> Scan,
                cardAction: ((CardItem.ID) -> Void)?)
    {
        self.init(arModel: arModel,
                  scanLabel: scanLabel,
                  cardLabel: { cardItem, isSelected in CardView(model: cardItem, isSelected: isSelected, action: cardAction) },
                  markerLabel: { state, icon in MarkerView(state: state, icon: icon) })
    }
}

extension SingleImageARCardView where Scan == ARScanView {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                image: Image,
                @ViewBuilder cardLabel: @escaping (CardItem, Bool) -> Card,
                @ViewBuilder markerLabel: @escaping (MarkerControl.State, Image?) -> Marker)
    {
        self.init(arModel: arModel,
                  scanLabel: { anchorPosition in ARScanView(image: image, anchorPosition: anchorPosition) },
                  cardLabel: cardLabel,
                  markerLabel: markerLabel)
    }
}

extension SingleImageARCardView where Marker == MarkerView {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                @ViewBuilder scanLabel: @escaping (Binding<CGPoint?>) -> Scan,
                @ViewBuilder cardLabel: @escaping (CardItem, Bool) -> Card)
    {
        self.init(arModel: arModel,
                  scanLabel: scanLabel,
                  cardLabel: cardLabel,
                  markerLabel: { state, icon in MarkerView(state: state, icon: icon) })
    }
}

extension SingleImageARCardView where Card == CardView<Text,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       _ConditionalContent<ImagePreview, DefaultIcon>,
                                                       _ConditionalContent<Text, EmptyView>,
                                                       CardItem> {
    
    public init(arModel: ARAnnotationViewModel<CardItem>,
                @ViewBuilder scanLabel: @escaping (Binding<CGPoint?>) -> Scan,
                @ViewBuilder markerLabel: @escaping (MarkerControl.State, Image?) -> Marker,
                cardAction: ((CardItem.ID) -> Void)?)
    {
        self.init(arModel: arModel,
                  scanLabel: scanLabel,
                  cardLabel: { cardItem, isSelected in CardView(model: cardItem, isSelected: isSelected, action: cardAction) },
                  markerLabel: markerLabel)
    }
}