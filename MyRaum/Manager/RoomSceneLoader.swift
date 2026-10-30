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
    //공간 전체를 감싸는 구의 반지름 - 카메라를 확대/축소, 이동할 수 있는 범위에 사용
    let radius: Float
    //가구 배치 편집 정보 - 저장된 USDZ 파일로 연 경우에는 가구를 구분할 수 없으므로 nil
    let furniture: FurnitureLayer?
}

//가구 배치를 편집할 때 사용하는 가구 노드와 바닥 정보
struct FurnitureLayer {
    //가구 노드를 붙이는 공간의 루트 노드 - 가구 목록에서 추가한 가구도 여기에 붙임
    let container: SCNNode
    //가구 ID → 가구 노드 (스캔 가구는 FurnitureModelBuilder.makeNode(for:in:), 추가한 가구는 makeNode(for:size:)가 만든 노드)
    private(set) var nodes: [UUID: SCNNode]
    //RoomPlan이 인식한 원래 위치 - 원래 위치로 되돌릴 때 사용 (추가한 가구는 없음)
    let originalTransforms: [UUID: simd_float4x4]
    //가구 노드의 로컬 좌표 기준 크기 (가로, 높이, 깊이)
    private(set) var dimensions: [UUID: SIMD3<Float>]
    //가구 종류 - 의자와 테이블처럼 서로 겹쳐도 되는 가구를 구분할 때 사용 (종류가 없는 가구는 nil)
    private(set) var categories: [UUID: FurnitureCategory]
    //가구를 옮길 때 손가락 위치를 투영하는 바닥 높이
    let floorY: Float
    //위에서 내려다본 바닥 다각형 (x, z) - 바닥 정보가 없으면 빈 배열
    let floor: [SIMD2<Float>]
    //가구 중심을 옮길 수 있는 x, z 범위
    let minimum: SIMD2<Float>
    let maximum: SIMD2<Float>
    //가구가 통과하지 못하는 벽
    let walls: [WallFootprint]
}

extension FurnitureLayer {
    //저장된 배치를 가구 노드에 덮어씀 - 원본에 없는 가구 ID는 무시
    //지운 스캔 가구는 장면에서 빼고, 추가한 가구는 새로 만들어서 붙임
    mutating func apply(_ arrangement: FurnitureArrangement) {
        for placement in arrangement.placements {
            guard let node = nodes[placement.id],
                  let transform = simd_float4x4(floats: placement.transform) else { continue }
            node.simdTransform = transform
        }
        for id in arrangement.removedIDs ?? [] {
            removeNode(id)
        }
        for addition in arrangement.additions ?? [] {
            addNode(for: addition)
        }
    }

    //추가한 가구의 노드를 만들어서 공간에 붙임 - 크기나 transform이 잘못된 항목은 무시
    @discardableResult
    mutating func addNode(for addition: FurnitureArrangement.Addition) -> SCNNode? {
        guard nodes[addition.id] == nil,
              let size = addition.dimensions,
              let transform = simd_float4x4(floats: addition.transform) else { return nil }
        let node = FurnitureModelBuilder.makeNode(for: addition.source, size: size)
        node.simdTransform = transform
        container.addChildNode(node)
        nodes[addition.id] = node
        dimensions[addition.id] = size
        categories[addition.id] = addition.source.category
        return node
    }

    mutating func removeNode(_ id: UUID) {
        nodes.removeValue(forKey: id)?.removeFromParentNode()
        dimensions[id] = nil
        categories[id] = nil
    }

    //hitTest는 가구의 부품 노드를 돌려주므로 부모를 따라 올라가며 가구 노드를 찾음
    func furnitureID(containing node: SCNNode) -> UUID? {
        var current: SCNNode? = node
        while let candidate = current {
            if let id = nodes.first(where: { $0.value === candidate })?.key {
                return id
            }
            current = candidate.parent
        }
        return nil
    }

    //점이 바닥 위에 있는지 - 바닥 정보가 없으면 옮길 수 있는 범위로 판단
    func isOnFloor(_ point: SIMD2<Float>) -> Bool {
        guard floor.count >= 3 else {
            return all(point .>= minimum) && all(point .<= maximum)
        }
        //점에서 +x 방향으로 그은 선이 바닥 테두리와 만나는 횟수가 홀수이면 안쪽
        var isInside = false
        var previous = floor[floor.count - 1]
        for current in floor {
            if (current.y > point.y) != (previous.y > point.y) {
                let x = previous.x + (point.y - previous.y) / (current.y - previous.y) * (current.x - previous.x)
                if point.x < x {
                    isInside.toggle()
                }
            }
            previous = current
        }
        return isInside
    }

    //바닥의 무게 중심 - ㄱ자 바닥처럼 무게 중심이 바닥 밖이면 옮길 수 있는 범위의 가운데
    var floorCenter: SIMD2<Float> {
        let fallback = (minimum + maximum) / 2
        guard floor.count >= 3 else { return fallback }
        var area: Float = 0
        var sum = SIMD2<Float>.zero
        var previous = floor[floor.count - 1]
        for current in floor {
            let cross = previous.x * current.y - current.x * previous.y
            area += cross
            sum += (previous + current) * cross
            previous = current
        }
        guard abs(area) > 1e-4 else { return fallback }
        let center = sum / (3 * area)
        return isOnFloor(center) ? center : fallback
    }
}

extension FurnitureArrangement.Addition {
    //저장된 크기 - 값이 3개가 아니거나 0 이하이면 nil
    var dimensions: SIMD3<Float>? {
        guard size.count == 3 else { return nil }
        let dimensions = SIMD3(size[0], size[1], size[2])
        return dimensions.min() > 0 ? dimensions : nil
    }
}

//3D 모델을 바라보는 카메라의 위치와 시야각
struct CameraPose: Codable {
    var transform: [Float]
    var fieldOfView: Double

    init(node: SCNNode) {
        transform = node.simdTransform.floats
        fieldOfView = Double(node.camera?.fieldOfView ?? 30)
    }

    func apply(to node: SCNNode) {
        guard let matrix = simd_float4x4(floats: transform) else { return }
        node.simdTransform = matrix
        node.camera?.fieldOfView = CGFloat(fieldOfView)
    }
}

//스캔이 끝난 공간 또는 저장된 공간 카드의 3D 모델 - 꾸미기 화면에서 사용
struct ScannedRoom {
    //CapturedRoom을 JSON으로 인코딩한 원본 데이터
    let roomData: Data?
    //RoomPlan 원본에서 뽑아낸 데이터 - 가구 배치를 바꾸면 공유용 USDZ 파일을 다시 만들 때 사용 (USDZ 파일로 연 경우 nil)
    let layout: RoomLayout?
    //공유용으로 내보낸 USDZ 파일
    let modelURL: URL
    //modelURL과 화면의 모델에 적용된 가구 배치
    let arrangement: FurnitureArrangement
    let roomScene: RoomScene
    //arrangement를 적용한 가구 목록 - 편집 중의 가구 목록은 furniture(applying:)로 구함
    let furniture: [FurnitureCategory]

    static func make(from capturedRoom: CapturedRoom) async throws -> ScannedRoom {
        try await make(layout: RoomLayout(capturedRoom), roomData: try? JSONEncoder().encode(capturedRoom), arrangement: FurnitureArrangement())
    }

    //저장된 공간 카드를 다시 열 때 사용 - 저장할 때의 카메라 각도와 가구 배치를 복원함
    //RoomPlan 원본 데이터가 있으면 모델과 USDZ 파일을 새로 만들고, 없으면 저장된 USDZ 파일을 사용
    @MainActor
    static func load(from record: SpaceRecord) async throws -> ScannedRoom {
        let room: ScannedRoom
        let arrangement = record.arrangement ?? FurnitureArrangement()
        if let roomData = record.roomData,
           let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: roomData) {
            room = try await make(layout: RoomLayout(capturedRoom), roomData: roomData, arrangement: arrangement)
        } else {
            let url = try record.writeModelFile()
            let roomScene = try await Task.detached(priority: .userInitiated) {
                try RoomSceneLoader.load(modelURL: url)
            }.value
            room = ScannedRoom(roomData: nil, layout: nil, modelURL: url, arrangement: arrangement, roomScene: roomScene, furniture: record.furniture)
        }

        record.cameraPose?.apply(to: room.roomScene.cameraNode)
        return room
    }

    static func make(layout: RoomLayout, roomData: Data?, arrangement: FurnitureArrangement) async throws -> ScannedRoom {
        let url = temporaryModelURL()

        let roomScene = try await Task.detached(priority: .userInitiated) {
            try ScannedRoom.writeModel(of: layout, arrangement: arrangement, to: url)
            let model = RoomModelBuilder.makeModel(from: layout)
            var furniture = model.furniture
            furniture.apply(arrangement)
            return RoomSceneLoader.prepare(model.scene, furniture: furniture)
        }.value

        return ScannedRoom(
            roomData: roomData,
            layout: layout,
            modelURL: url,
            arrangement: arrangement,
            roomScene: roomScene,
            furniture: furniture(of: layout, applying: arrangement)
        )
    }

    //가구 배치를 적용한 가구 목록 - 지운 스캔 가구는 빼고 추가한 가구를 더함
    //USDZ 파일로 연 경우에는 배치를 편집할 수 없으므로 저장된 가구 목록을 그대로 사용
    func furniture(applying arrangement: FurnitureArrangement) -> [FurnitureCategory] {
        guard let layout else { return furniture }
        return Self.furniture(of: layout, applying: arrangement)
    }

    //저장할 USDZ 파일 - 가구 배치가 바뀌었으면 바뀐 배치로 파일을 새로 만들고, 그대로이면 기존 파일을 사용
    func modelURL(applying arrangement: FurnitureArrangement) async throws -> URL {
        guard let layout, arrangement != self.arrangement else { return modelURL }
        let url = Self.temporaryModelURL()
        try await Task.detached(priority: .userInitiated) {
            try ScannedRoom.writeModel(of: layout, arrangement: arrangement, to: url)
        }.value
        return url
    }
}

private extension ScannedRoom {
    static func temporaryModelURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("usdz")
    }

    static func furniture(of layout: RoomLayout, applying arrangement: FurnitureArrangement) -> [FurnitureCategory] {
        let scanned = layout.objects.filter { !arrangement.isRemoved($0.id) }.map(\.category)
        let added = (arrangement.additions ?? []).compactMap(\.source.category)
        return scanned + added
    }

    //원본으로 장면을 만든 뒤 가구 노드만 저장된 배치로 옮김
    //RoomLayout을 고쳐서 다시 만들면 가구의 앞뒤 방향이 다시 계산되어 가구가 뒤돌아설 수 있음
    static func writeModel(of layout: RoomLayout, arrangement: FurnitureArrangement, to url: URL) throws {
        let model = RoomModelBuilder.makeModel(from: layout)
        var furniture = model.furniture
        furniture.apply(arrangement)
        //모서리가 둥근 SCNBox는 USDZ로 내보내면 형태가 깨지므로 파일용 모델은 둥근 모서리 없이 따로 만듦
        RoomModelBuilder.removeRoundedEdges(in: model.scene)
        //카메라와 조명을 추가하기 전의 모델만 파일로 저장
        guard model.scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) else {
            throw RoomSceneError.exportFailed
        }
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
    
    static func prepare(_ scene: SCNScene, furniture: FurnitureLayer? = nil) -> RoomScene {
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

        return RoomScene(scene: scene, cameraNode: cameraNode, target: SCNVector3(center), radius: radius, furniture: furniture)
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
