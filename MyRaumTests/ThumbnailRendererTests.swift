//
//  ThumbnailRendererTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import SceneKit
import UIKit
@testable import MyRaum

//USDZ 썸네일 렌더링을 확인하는 테스트
@MainActor
struct ThumbnailRendererTests {
    //테스트용 USDZ 파일을 만드는 함수
    private func makeTestUSDZ() throws -> URL {
        let scene = SCNScene()
        let box = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        scene.rootNode.addChildNode(box)
        
        let url = FileManager.default.temporaryDirectory
            .appending(path: "thumbnail-\(UUID().uuidString).usdz")
        
        let exported = scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
        try #require(exported)
        
        return url
    }
    
    @Test("USDZ에서 PNG 썸네일을 만든다")
    func rendersThumbnailFromUSDZ() throws {
        let url = try makeTestUSDZ()
        defer { try? FileManager.default.removeItem(at: url) }
        
        let data = try #require(ThumbnailRenderer().renderThumbnail(of: url, size: CGSize(width: 128, height: 128)))
        let image = try #require(UIImage(data: data))
        
        #expect(image.size.width == 128)
        #expect(image.size.height == 128)
    }
    
    @Test("파일이 없으면 nil을 리턴하고 크래시하지 않는다")
    func returnsNilForMissingFile() {
        let missing = FileManager.default.temporaryDirectory.appending(path: "does-not-exist.usdz")
        
        #expect(ThumbnailRenderer().renderThumbnail(of: missing, size: CGSize(width: 64, height: 64)) == nil)
    }
}
