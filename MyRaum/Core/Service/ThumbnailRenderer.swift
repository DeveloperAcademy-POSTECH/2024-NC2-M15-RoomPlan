//
//  ThumbnailRenderer.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import UIKit
import SceneKit

//USDZ 모델을 목록·지도 마커용 썸네일 이미지로 만드는 역할
protocol ThumbnailRendering {
    func renderThumbnail(of modelURL: URL, size: CGSize) -> Data?
}

//오프스크린 렌더로 썸네일 PNG를 만드는 구현체
//상세 화면의 3D 카드는 RealityView를 쓰고(§3.1), 여기서는 정지 이미지 한 장만 필요하므로
//오프스크린 렌더가 간단한 SceneKit을 사용한다
final class ThumbnailRenderer: ThumbnailRendering {
    func renderThumbnail(of modelURL: URL, size: CGSize = CGSize(width: 512, height: 512)) -> Data? {
        guard FileManager.default.fileExists(atPath: modelURL.path()) else {
            print("Model file not found for thumbnail: \(modelURL.lastPathComponent)")
            return nil
        }
        
        guard let scene = try? SCNScene(url: modelURL) else {
            print("Failed to load USDZ scene for thumbnail")
            return nil
        }
        
        //모델 전체가 담기도록 카메라를 배치
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        let (minBounds, maxBounds) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minBounds.x + maxBounds.x) / 2,
            (minBounds.y + maxBounds.y) / 2,
            (minBounds.z + maxBounds.z) / 2
        )
        let extent = max(
            maxBounds.x - minBounds.x,
            max(maxBounds.y - minBounds.y, maxBounds.z - minBounds.z)
        )
        let distance = max(Float(extent) * 1.8, 1.0)
        
        cameraNode.position = SCNVector3(center.x + distance, center.y + distance, center.z + distance)
        cameraNode.look(at: center)
        
        //형태가 드러나도록 기본 조명을 켠다
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.autoenablesDefaultLighting = true
        renderer.pointOfView = cameraNode
        
        let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
        return image.pngData()
    }
}
