//
//  ModelEntityLoadingTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import SceneKit
import RealityKit
@testable import MyRaum

//3D 카드가 USDZ를 실제로 읽어 들일 수 있는지 확인하는 테스트
@MainActor
struct ModelEntityLoadingTests {
    private func makeTestUSDZ() throws -> URL {
        let scene = SCNScene()
        scene.rootNode.addChildNode(SCNNode(geometry: SCNBox(width: 2, height: 1, length: 1, chamferRadius: 0)))
        
        let url = FileManager.default.temporaryDirectory
            .appending(path: "entity-\(UUID().uuidString).usdz")
        try #require(scene.write(to: url, options: nil, delegate: nil, progressHandler: nil))
        
        return url
    }
    
    @Test("USDZ에서 ModelEntity를 만들고 크기를 읽을 수 있다")
    func loadsModelEntityFromUSDZ() async throws {
        let url = try makeTestUSDZ()
        defer { try? FileManager.default.removeItem(at: url) }
        
        let entity = try await ModelEntity(contentsOf: url)
        let extents = entity.visualBounds(relativeTo: nil).extents
        
        #expect(extents.x > 0)
        #expect(extents.y > 0)
        #expect(extents.z > 0)
        
        //카드 안에 담기도록 계산한 배율이 유효한 범위여야 한다
        let scale = Space3DView.fittingScale(extents: extents)
        #expect(scale > 0)
        #expect(scale.isFinite)
    }
}
