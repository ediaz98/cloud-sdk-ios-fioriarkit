//
//  ARScanView.swift
//
//
//  Created by O'Brien, Patrick on 4/8/21.
//

import FioriThemeManager
import SwiftUI

/**
 Scanning View which displays a collapsable image to display for anchor detection. The anchor is still detectable when uncollapsed and the View will fade out after detection.
 
  - Parameters:
    - image: The image that is displayed in the View which represents a detectable anchor
    - anchorPosition: The position of the anchor on screen after detection
 */

public struct ARScanView: View {
    let image: Image
    @Binding var anchorPosition: CGPoint?
    
    public var body: some View {
        ZStack {
            if anchorPosition != nil {
                ImageMatchedView(anchorPosition: $anchorPosition)
            } else {
                CollapsingView(image: image)
            }
        }
        .animation(.easeInOut(duration: 1.2), value: anchorPosition)
    }
}

private struct CollapsingView: View {
    let image: Image
    let screen = UIScreen.main.bounds
    
    @State var isScanning = false
    @Namespace var nameSpace
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var collapsedRatio: CGFloat {
        self.landscapeRegular ? self.screen.width * 0.2 : self.screen.width * 0.3
    }
    
    var landscapeRegular: Bool {
        self.horizontalSizeClass == .regular && self.screen.width > self.screen.height
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .cornerRadius(isScanning ? 8 : 0)
                .matchedGeometryEffect(id: isScanning ? "image" : "background", in: nameSpace, isSource: false)
            
            VStack {
                image
                    .resizable()
                    .cornerRadius(8)
                    .padding(.all, 8)
                    .scaledToFit()
                    .background(
                        ScanGuideCorners()
                            .stroke(isScanning ? Color.clear : Color.white, lineWidth: 2)
                    )
                    .matchedGeometryEffect(id: isScanning ? "image" : "background", in: nameSpace, isSource: false)
                    .padding(.horizontal, 56)
                    .padding(.top, verticalSizeClass == .compact ? 80 : 216)
                    .onTapGesture(perform: buttonAction)
                    .allowsHitTesting(isScanning)
                
                Text("Point your camera at this image to start augmented reality experience")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, verticalSizeClass == .compact ? 44 : 80)
                    .opacity(isScanning ? 0 : 1)
                
                Button(action: { buttonAction() }, label: {
                    Text("Begin Scan")
                        .frame(width: 201, height: 40)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.preferredColor(.tintColor, background: .lightConstant))
                        )
                })
                    .padding(.bottom, verticalSizeClass == .compact ? 48 : 216)
                    .opacity(isScanning ? 0 : 1)
            }
            
            if isScanning {
                ScanGuide()
            }
            
            VStack {
                Spacer()
                image
                    .resizable()
                    .cornerRadius(8)
                    .scaledToFit()
                    .matchedGeometryEffect(id: "image", in: nameSpace)
                    .frame(width: collapsedRatio)
                    .padding(.bottom, 34)
                    .offset(x: verticalSizeClass == .compact ? screen.width * 0.33 : 0)
                    .opacity(0)
            }
        }
    }
    
    func buttonAction() {
        withAnimation(.interpolatingSpring(mass: 2, stiffness: 700, damping: 52)) {
            isScanning.toggle()
        }
    }
}

private struct ScanGuide: View {
    @State var scale: CGFloat = 1
    
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 22))
            .foregroundColor(.white)
            .background(
                ScanGuideCorners()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 80, height: 80, alignment: .center)
            )
            .scaleEffect(scale)
            .animateOnAppear(animation: Animation.easeInOut(duration: 0.2)) {
                scale = 1.5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        scale = 1
                    }
                }
            }
    }
}

private struct ImageMatchedView: View {
    @Binding var anchorPosition: CGPoint?
    @State var opacity: Double = 0
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 38))
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0 / 255, green: 90 / 255, blue: 38 / 255, opacity: 0.6))
                    .frame(width: 120, height: 120)
                    .padding(.all, 3)
                    .background(
                        ScanGuideCorners()
                            .stroke(Color.white, lineWidth: 2)
                    )
            )
            .position(anchorPosition!)
            .animation(nil, value: anchorPosition!)
            .opacity(opacity)
            .animateOnAppear(animation: Animation.easeInOut(duration: 1)) {
                opacity = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(Animation.easeInOut(duration: 1)) {
                        opacity = 0
                    }
                }
            }
    }
}

internal struct ScanGuideCorners: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        // Top left Corner
        path.move(to: CGPoint(x: 0, y: 24))
        path.addLine(to: CGPoint(x: 0, y: 10))
        path.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 24, y: 0))
        
        // Top Right Corner
        path.move(to: CGPoint(x: rect.size.width - 24, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width - 10, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.size.width, y: 10), control: CGPoint(x: rect.size.width, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width, y: 24))
        
        // Bottom Right Corner
        path.move(to: CGPoint(x: rect.size.width, y: rect.size.height - 24))
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height - 10))
        path.addQuadCurve(to: CGPoint(x: rect.size.width - 10, y: rect.size.height), control: CGPoint(x: rect.size.width, y: rect.size.height))
        path.addLine(to: CGPoint(x: rect.size.width - 24, y: rect.size.height))
        
        // Bottom Left Corner
        path.move(to: CGPoint(x: 24, y: rect.size.height))
        path.addLine(to: CGPoint(x: 10, y: rect.size.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.size.height - 10), control: CGPoint(x: 0, y: rect.size.height))
        path.addLine(to: CGPoint(x: 0, y: rect.size.height - 24))
        
        return path
    }
}
