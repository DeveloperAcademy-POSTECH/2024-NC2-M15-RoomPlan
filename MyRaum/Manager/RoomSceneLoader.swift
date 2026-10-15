//
//  RoomSceneLoader.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SceneKit
import RoomPlan

//SceneKit으로 보여줄 3D 공간 - 씬, 카메라, 카메라가 바라보는 중심점
struct RoomScene {
    let scene: SCNScene
    let cameraNode: SCNNode
    let target: SCNVector3
}

//스캔이 끝난 공간 - 꾸미기 화면에서 사용
struct ScannedRoom {
    //CapturedRoom을 JSON으로 인코딩한 원본 데이터
    let roomData: Data?
    //공유용으로 내보낸 USDZ 파일
    let modelURL: URL
    let roomScene: RoomScene
    let furniture: [FurnitureCategory]

    static func make(from capturedRoom: CapturedRoom) async throws -> ScannedRoom {
        try await make(layout: RoomLayout(capturedRoom), roomData: try? JSONEncoder().encode(capturedRoom))
    }

    static func make(layout: RoomLayout, roomData: Data?) async throws -> ScannedRoom {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("usdz")

        let roomScene = try await Task.detached(priority: .userInitiated) {
            let scene = RoomModelBuilder.makeScene(from: layout)
            //카메라와 조명을 추가하기 전의 모델만 파일로 저장
            guard scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) else {
                throw RoomSceneError.exportFailed
            }
            return RoomSceneLoader.prepare(scene)
        }.value

        return ScannedRoom(
            roomData: roomData,
            modelURL: url,
            roomScene: roomScene,
            furniture: layout.objects.map(\.category)
        )
    }
}

enum RoomSceneError: Error {
    case exportFailed
}

//3D 공간을 화면에 보여줄 수 있도록 조명, 카메라를 설정하는 클래스
enum RoomSceneLoader {
    //저장된 공간 카드의 3D 모델을 불러옴
    //RoomPlan 원본 데이터가 있으면 다시 만들고, 없으면 저장된 USDZ 파일을 사용
    static func load(roomData: Data?, modelURL: URL) throws -> RoomScene {
        if let roomData, let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: roomData) {
            return prepare(RoomModelBuilder.makeScene(from: RoomLayout(capturedRoom)))
        }
        let scene = try SCNScene(url: modelURL, options: nil)
        RoomPalette.restore(in: scene)
        return prepare(scene)
    }

    static func prepare(_ scene: SCNScene) -> RoomScene {
        scene.background.contents = UIColor.clear

        let (minimum, maximum) = worldBounds(of: scene.rootNode)
        let center = (minimum + maximum) / 2
        let radius = max(simd_length(maximum - minimum) / 2, 0.5)

        addLights(to: scene, center: center, radius: radius)
        let cameraNode = makeCamera(center: center, radius: radius)
        scene.rootNode.addChildNode(cameraNode)

        return RoomScene(scene: scene, cameraNode: cameraNode, target: SCNVector3(center))
    }
}

private extension RoomSceneLoader {
    //모든 지오메트리를 감싸는 월드 좌표계 기준의 바운딩 박스
    static func worldBounds(of root: SCNNode) -> (SIMD3<Float>, SIMD3<Float>) {
        var minimum = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maximum = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        var found = false

        root.enumerateHierarchy { node, _ in
            guard node.geometry != nil, !node.isHidden else { return }
            let (localMin, localMax) = node.boundingBox
            for x in [localMin.x, localMax.x] {
                for y in [localMin.y, localMax.y] {
                    for z in [localMin.z, localMax.z] {
                        let point = SIMD3<Float>(node.convertPosition(SCNVector3(x, y, z), to: nil))
                        minimum = simd_min(minimum, point)
                        maximum = simd_max(maximum, point)
                        found = true
                    }
                }
            }
        }

        return found ? (minimum, maximum) : (SIMD3(repeating: -1), SIMD3(repeating: 1))
    }

    //은은한 환경광 + 그림자가 부드러운 위쪽 조명
    static func addLights(to scene: SCNScene, center: SIMD3<Float>, radius: Float) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 520
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        let light = SCNLight()
        light.type = .directional
        light.intensity = 620
        light.castsShadow = true
        light.shadowMode = .forward
        light.shadowColor = UIColor(white: 0, alpha: 0.3)
        light.shadowRadius = 6
        light.shadowSampleCount = 16
        light.shadowMapSize = CGSize(width: 2048, height: 2048)
        //공간 전체가 그림자 범위에 들어오도록 공간 크기에 맞춰 직접 설정
        light.automaticallyAdjustsShadowProjection = false
        light.orthographicScale = CGFloat(radius * 1.1)
        light.zNear = 0.1
        light.zFar = CGFloat(radius * 6)
        light.shadowBias = 2
        directional.light = light
        directional.simdPosition = center + simd_normalize(SIMD3<Float>(-0.5, 1.6, 0.8)) * radius * 3
        directional.simdLook(at: center)
        scene.rootNode.addChildNode(directional)
    }

    //공간 전체가 화면에 들어오도록 위에서 비스듬히 내려다보는 카메라
    //시야각을 좁게 해서 모형을 내려다보는 듯한 아이소메트릭 느낌을 줌
    static func makeCamera(center: SIMD3<Float>, radius: Float) -> SCNNode {
        let camera = SCNCamera()
        camera.projectionDirection = .horizontal
        camera.fieldOfView = 30
        camera.automaticallyAdjustsZRange = true

        let halfFieldOfView = Float(camera.fieldOfView / 2) * .pi / 180
        let distance = radius / sin(halfFieldOfView)
        //가까운 벽에 가려지지 않고 내부가 잘 보이도록 높은 곳에서 내려다봄
        let elevation: Float = 50 * .pi / 180
        let azimuth: Float = 35 * .pi / 180
        let direction = SIMD3<Float>(
            sin(azimuth) * cos(elevation),
            sin(elevation),
            cos(azimuth) * cos(elevation)
        )

        let node = SCNNode()
        node.camera = camera
        node.simdPosition = center + direction * distance
        node.simdLook(at: center)
        return node
    }
}
