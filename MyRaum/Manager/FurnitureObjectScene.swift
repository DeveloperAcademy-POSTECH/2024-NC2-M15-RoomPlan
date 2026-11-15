//
//  FurnitureObjectScene.swift
//  MyRaum
//
//  Created by Yune Cho on 11/15/26.
//

import SceneKit
import simd

//가구 하나만 놓인 3D 장면 - 오브젝트 탭의 3D 보기와 미리보기 이미지에 사용
//가구는 FurnitureLibrary가 알려준 source와 크기로 FurnitureModelBuilder가 만들므로
//스캔한 가구도 FurnitureModelBuilder.makeNode(for:size:)만 확장하면 그대로 보여줄 수 있음
enum FurnitureObjectScene {
    //showsBase: 그림자를 받는 둥근 받침 - 미리보기 이미지에서는 가구만 크게 보이도록 뺌
    static func make(for object: FurnitureObject, showsBase: Bool = true) -> RoomScene {
        let scene = SCNScene()

        let furniture = FurnitureModelBuilder.makeNode(for: object.source, size: object.size)
        //밑면이 y = 0에 닿도록 올림 - 앞쪽(+z)이 카메라 쪽을 봄
        furniture.simdPosition = [0, object.size.y / 2, 0]
        scene.rootNode.addChildNode(furniture)

        if showsBase {
            let radius = simd_length(SIMD2(object.size.x, object.size.z)) / 2 + 0.08
            scene.rootNode.addCylinder(center: [0, -0.01, 0], radiusX: radius, radiusZ: radius, height: 0.02, material: baseMaterial)
        }

        //옆모습이 잘 보이도록 공간보다 낮은 각도에서 바라봄
        return RoomSceneLoader.prepare(scene, elevation: 22)
    }

    private static let baseMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.lightingModel = .lambert
        material.diffuse.contents = UIColor(white: 0.86, alpha: 1)
        return material
    }()
}

//가구 목록에 보여줄 미리보기 이미지를 만들고 메모리에 보관하는 클래스
//가구 모양은 코드로 만들기 때문에 이미지를 앱에 넣지 않고 처음 보여줄 때 한 번 렌더링함
//actor라서 메인 스레드를 막지 않고, 여러 셀이 동시에 요청해도 하나씩 렌더링함
actor FurnitureThumbnailRenderer {
    static let shared = FurnitureThumbnailRenderer()

    private var cache: [Key: UIImage] = [:]
    private lazy var renderer: SCNRenderer? = MTLCreateSystemDefaultDevice().map { SCNRenderer(device: $0, options: nil) }

    private struct Key: Hashable {
        let source: FurnitureSource
        let pixelSize: Int
    }

    //pointSize: 화면에 보여줄 크기, scale: 화면 배율
    func thumbnail(for object: FurnitureObject, pointSize: CGFloat, scale: CGFloat) -> UIImage? {
        let pixelSize = Int((pointSize * scale).rounded())
        let key = Key(source: object.source, pixelSize: pixelSize)
        if let image = cache[key] {
            return image
        }
        guard pixelSize > 0, let renderer else { return nil }

        let roomScene = FurnitureObjectScene.make(for: object, showsBase: false)
        //화면에 떠 있는 공간 모델과 재질을 함께 쓰지 않도록 재질을 복사함
        roomScene.scene.rootNode.enumerateHierarchy { node, _ in
            guard let geometry = node.geometry else { return }
            geometry.materials = geometry.materials.map { ($0.copy() as? SCNMaterial) ?? $0 }
        }

        renderer.scene = roomScene.scene
        renderer.pointOfView = roomScene.cameraNode
        let snapshot = renderer.snapshot(atTime: 0, with: CGSize(width: pixelSize, height: pixelSize), antialiasingMode: .multisampling4X)
        renderer.scene = nil

        guard let cgImage = snapshot.cgImage else { return nil }
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        cache[key] = image
        return image
    }
}
