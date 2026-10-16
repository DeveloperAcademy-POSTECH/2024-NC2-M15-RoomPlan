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

//3D 모델을 바라보는 카메라의 위치와 시야각
struct CameraPose: Codable {
    var transform: [Float]
    var fieldOfView: Double
    
    init(node: SCNNode) {
        let matrix = node.simdTransform
        transform = [matrix.columns.0, matrix.columns.1, matrix.columns.2, matrix.columns.3].flatMap { [$0.x, $0.y, $0.z, $0.w] }
        fieldOfView = Double(node.camera?.fieldOfView ?? 30)
    }
    
    func apply(to node: SCNNode) {
        guard transform.count == 16 else { return }
        let column = { (index: Int) in SIMD4<Float>(transform[index * 4], transform[index * 4 + 1], transform[index * 4 + 2], transform[index * 4 + 3]) }
        node.simdTransform = simd_float4x4(column(0), column(1), column(2), column(3))
        node.camera?.fieldOfView = CGFloat(fieldOfView)
    }
}

//스캔이 끝난 공간 또는 저장된 공간 카드의 3D 모델 - 꾸미기 화면에서 사용
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

    //저장된 공간 카드를 다시 열 때 사용 - 저장할 때의 카메라 각도를 복원함
    //RoomPlan 원본 데이터가 있으면 모델과 USDZ 파일을 새로 만들고, 없으면 저장된 USDZ 파일을 사용
    @MainActor
    static func load(from record: SpaceRecord) async throws -> ScannedRoom {
        let room: ScannedRoom
        if let roomData = record.roomData,
           let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: roomData) {
            room = try await make(layout: RoomLayout(capturedRoom), roomData: roomData)
        } else {
            let url = try record.writeModelFile()
            let roomScene = try await Task.detached(priority: .userInitiated) {
                try RoomSceneLoader.load(modelURL: url)
            }.value
            room = ScannedRoom(roomData: nil, modelURL: url, roomScene: roomScene, furniture: record.furniture)
        }
        
        record.cameraPose?.apply(to: room.roomScene.cameraNode)
        return room
    }
    
    static func make(layout: RoomLayout, roomData: Data?) async throws -> ScannedRoom {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("usdz")
        
        let roomScene = try await Task.detached(priority: .userInitiated) {
            //모서리가 둥근 SCNBox는 USDZ로 내보내면 형태가 깨지므로 파일용 모델은 둥근 모서리 없이 따로 만듦
            let exportScene = RoomModelBuilder.makeScene(from: layout)
            RoomModelBuilder.removeRoundedEdges(in: exportScene)
            //카메라와 조명을 추가하기 전의 모델만 파일로 저장
            guard exportScene.write(to: url, options: nil, delegate: nil, progressHandler: nil) else {
                throw RoomSceneError.exportFailed
            }
            return RoomSceneLoader.prepare(RoomModelBuilder.makeScene(from: layout))
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
    //저장된 USDZ 파일로 3D 모델을 불러옴
    static func load(modelURL: URL) throws -> RoomScene {
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
        
        //백그라운드 스레드에서 만든 씬은 암묵적 트랜잭션이 커밋되지 않아서
        //나중에 메인 스레드에서 바꾼 카메라 위치를 덮어쓸 수 있으므로 바로 커밋함
        SCNTransaction.flush()

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
