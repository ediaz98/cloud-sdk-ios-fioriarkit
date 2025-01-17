//
// RCScanner.swift
// GENERATED CONTENT FROM APPLE.
//

import Combine
import Foundation
import RealityKit
import simd

/// Creates a programmatic representation of the Reality Composer Scene  from an Image or Object Anchor from a .rcproject File.

@available(iOS 13.0, macOS 10.15, *)
internal enum RCScanner {
    private enum LoadRealityFileError: Error {
        case fileNotFound(String)
    }

    private static var streams = [Combine.AnyCancellable]()

    internal static func loadScene(rcFileName: String, sceneName: String) throws -> RCScanner.Scene {
        guard let realityFileURL = Foundation.Bundle.main.url(forResource: rcFileName, withExtension: "reality") else {
            throw RCScanner.LoadRealityFileError.fileNotFound("\(rcFileName).reality")
        }

        let realityFileSceneURL = realityFileURL.appendingPathComponent(sceneName, isDirectory: false)
        let anchorEntity = try RCScanner.Scene.loadAnchor(contentsOf: realityFileSceneURL)
        return self.createScene(from: anchorEntity)
    }
    
    internal static func loadSceneFromRealityFile(realityFileURL: URL, sceneName: String) throws -> RCScanner.Scene {
        let realityFileSceneURL = realityFileURL.appendingPathComponent(sceneName, isDirectory: false)
        let anchorEntity = try RCScanner.Scene.loadAnchor(contentsOf: realityFileSceneURL)
        return self.createScene(from: anchorEntity)
    }
    
    internal static func loadSceneFromUsdzFile(usdzFileURL: URL) throws -> RCScanner.Scene {
        let anchorEntity = try RCScanner.Scene.loadAnchor(contentsOf: usdzFileURL)
        return self.createScene(from: anchorEntity)
    }

    internal static func loadSceneAsync(rcFileName: String, completion: @escaping (Swift.Result<RCScanner.Scene, Swift.Error>) -> Void) {
        guard let realityFileURL = Foundation.Bundle(for: RCScanner.Scene.self).url(forResource: rcFileName, withExtension: "reality") else {
            completion(.failure(RCScanner.LoadRealityFileError.fileNotFound("\(rcFileName).reality")))
            return
        }

        var cancellable: Combine.AnyCancellable?
        let realityFileSceneURL = realityFileURL.appendingPathComponent("Scene", isDirectory: false)
        let loadRequest = RCScanner.Scene.loadAnchorAsync(contentsOf: realityFileSceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case .failure(let error) = loadCompletion {
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            completion(.success(RCScanner.createScene(from: entity)))
        })
        cancellable?.store(in: &self.streams)
    }

    internal static func createScene(from anchorEntity: RealityKit.AnchorEntity) -> RCScanner.Scene {
        let scene = RCScanner.Scene()
        scene.name = "Scene"
        scene.anchoring = anchorEntity.anchoring
        scene.addChild(anchorEntity)
        return scene
    }

    /// A convenience class which subclasses Entity and conforms to HasAnchoring
    internal class Scene: RealityKit.Entity, RealityKit.HasAnchoring {}
}
