//
//  FurnitureEditor.swift
//  MyRaum
//
//  Created by Yune Cho on 10/29/26.
//

import SceneKit
import simd

//꾸미기 화면에서 스캔된 가구를 옮기고 돌리는 편집 상태
//RoomSceneView의 제스처가 이 클래스로 가구 노드를 움직이고, 움직임이 끝나면 StoryDraft에 최종 위치를 저장함
@MainActor
@Observable
final class FurnitureEditor {
    private(set) var isEditing: Bool = false
    private(set) var selectedID: UUID?
    //선택된 가구가 원래 위치에서 바뀌었는지 - 원래 위치로 버튼을 활성화할 때 사용
    private(set) var isSelectedMoved: Bool = false

    let layer: FurnitureLayer
    private let draft: StoryDraft

    @ObservationIgnored private var highlightNode: SCNNode?
    //드래그를 시작할 때 가구 중심과 손가락이 가리킨 바닥 위치의 차이 (x, z)
    @ObservationIgnored private var dragOffset: SIMD2<Float>?
    @ObservationIgnored private var rotationStart: simd_quatf?
    @ObservationIgnored private var rotationStartPosition: SIMD2<Float>?
    @ObservationIgnored private var rotationStep: Int = 0
    //벽마다 옮기기 시작할 때 이미 겹쳐 있던 정도 - 스캔할 때부터 벽에 살짝 묻혀 있던 가구가 튀지 않게 함
    @ObservationIgnored private var wallContacts: [WallContact] = []

    //두 손가락으로 돌릴 때 맞추는 각도 단위
    static let snapAngle: Float = 15 * .pi / 180
    //빠르게 옮겨도 벽을 건너뛰지 않도록 나눠서 검사하는 거리
    static let collisionStep: Float = 0.05

    init(layer: FurnitureLayer, draft: StoryDraft) {
        self.layer = layer
        self.draft = draft
    }

    var canEdit: Bool {
        !layer.nodes.isEmpty
    }

    func setEditing(_ isOn: Bool) {
        isEditing = isOn
        if !isOn {
            select(nil)
        }
    }

    //가구를 선택하고 하이라이트 - nil이면 선택 해제
    func select(_ id: UUID?) {
        guard id != selectedID else { return }
        highlightNode?.removeFromParentNode()
        highlightNode = nil
        dragOffset = nil
        rotationStart = nil
        selectedID = id

        guard let id, let node = layer.nodes[id] else {
            isSelectedMoved = false
            return
        }
        let highlight = Self.makeHighlight(size: layer.dimensions[id] ?? SIMD3(repeating: 0.5))
        node.addChildNode(highlight)
        highlightNode = highlight
        isSelectedMoved = isMoved(id)
        HapticManager.selection()
    }
}

// MARK: - Move & Rotate
extension FurnitureEditor {
    //point: 드래그를 시작한 손가락 위치를 바닥 평면에 투영한 점
    func beginMove(_ id: UUID, from point: SIMD3<Float>) {
        select(id)
        guard let node = layer.nodes[id] else { return }
        dragOffset = SIMD2(node.simdPosition.x - point.x, node.simdPosition.z - point.z)
        wallContacts = currentWallContacts(of: id, node: node)
    }

    //높이는 그대로 두고 x, z만 옮김 - 바닥 밖으로 너무 멀리 나가지 않도록 범위를 제한
    //벽에 닿으면 벽을 따라 미끄러지고 벽을 통과하지는 못함
    func move(to point: SIMD3<Float>) {
        guard let id = selectedID, let node = layer.nodes[id], let offset = dragOffset else { return }
        let target = simd_clamp(SIMD2(point.x, point.z) + offset, layer.minimum, layer.maximum)

        var position = flatPosition(of: node)
        let delta = target - position
        let count = min(max(Int((simd_length(delta) / Self.collisionStep).rounded(.up)), 1), 100)
        for _ in 0..<count {
            position = resolvedPosition(position + delta / Float(count), of: id, node: node)
        }
        node.simdPosition = SIMD3(position.x, node.simdPosition.y, position.y)
    }

    func endMove() {
        guard dragOffset != nil else { return }
        dragOffset = nil
        commit()
    }

    @discardableResult
    func beginRotation() -> Bool {
        guard let id = selectedID, let node = layer.nodes[id] else { return false }
        rotationStart = node.simdOrientation
        rotationStartPosition = flatPosition(of: node)
        rotationStep = 0
        wallContacts = currentWallContacts(of: id, node: node)
        return true
    }

    //angle: 위에서 내려다볼 때 반시계 방향이 양수 (y축 기준)
    //snapAngle 단위로 맞추고, 단계가 바뀌면 햅틱으로 알려줌
    //돌아간 단계가 있으면 true
    @discardableResult
    func rotate(by angle: Float) -> Bool {
        guard let id = selectedID, let node = layer.nodes[id],
              let start = rotationStart, let startPosition = rotationStartPosition else { return false }
        let step = Int((angle / Self.snapAngle).rounded())
        if step != rotationStep {
            rotationStep = step
            node.simdOrientation = simd_quatf(angle: Float(step) * Self.snapAngle, axis: [0, 1, 0]) * start
            //돌리다가 벽에 닿으면 벽 밖으로 밀어냄 - 다시 원래 각도로 돌리면 처음 위치로 돌아옴
            let position = resolvedPosition(startPosition, of: id, node: node, tightensContacts: false)
            node.simdPosition = SIMD3(position.x, node.simdPosition.y, position.y)
            HapticManager.selection()
        }
        return step != 0
    }

    func endRotation() {
        guard rotationStart != nil else { return }
        rotationStart = nil
        rotationStartPosition = nil
        rotationStep = 0
        commit()
    }

    //위에서 내려다볼 때 시계 방향으로 90도 회전
    func rotateSelectedQuarter() {
        guard let id = selectedID, let node = layer.nodes[id] else { return }
        wallContacts = currentWallContacts(of: id, node: node)
        node.simdOrientation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0]) * node.simdOrientation
        let position = resolvedPosition(flatPosition(of: node), of: id, node: node)
        node.simdPosition = SIMD3(position.x, node.simdPosition.y, position.y)
        commit()
    }

    //RoomPlan이 인식한 원래 위치와 방향으로 되돌림
    func resetSelected() {
        guard let id = selectedID, let node = layer.nodes[id], let original = layer.originalTransforms[id] else { return }
        node.simdTransform = original
        commit()
    }
}

// MARK: - Collision
private extension FurnitureEditor {
    struct WallContact {
        //이 깊이까지는 겹쳐도 밀어내지 않음 - 벽에서 멀어지면 줄어들고 다시 늘어나지 않음
        var allowedDepth: Float
        //처음부터 겹쳐 있던 벽은 그때 가구가 있던 쪽으로만 밀어냄
        var side: Float?
    }

    func flatPosition(of node: SCNNode) -> SIMD2<Float> {
        SIMD2(node.simdPosition.x, node.simdPosition.z)
    }

    //가구 노드의 방향과 크기로 만든 바닥면 - 벽에 닿기만 한 것은 겹친 것으로 보지 않도록 조금 줄임
    func footprint(of id: UUID, node: SCNNode, at center: SIMD2<Float>) -> FurnitureFootprint {
        let transform = node.simdTransform
        let size = layer.dimensions[id] ?? SIMD3(repeating: 0.1)
        let margin: Float = 0.005
        return FurnitureFootprint(
            center: center,
            axisX: Self.flatAxis(transform.columns.0, fallback: [1, 0]),
            axisZ: Self.flatAxis(transform.columns.2, fallback: [0, 1]),
            halfX: max(size.x / 2 - margin, 0.01),
            halfZ: max(size.z / 2 - margin, 0.01)
        )
    }

    static func flatAxis(_ column: SIMD4<Float>, fallback: SIMD2<Float>) -> SIMD2<Float> {
        let axis = SIMD2(column.x, column.z)
        return simd_length(axis) > 1e-4 ? simd_normalize(axis) : fallback
    }

    func currentWallContacts(of id: UUID, node: SCNNode) -> [WallContact] {
        let furniture = footprint(of: id, node: node, at: flatPosition(of: node))
        let roomCenter = (layer.minimum + layer.maximum) / 2
        return layer.walls.map { wall in
            guard var penetration = FurnitureCollision.penetration(of: furniture, into: wall) else {
                return WallContact(allowedDepth: 0, side: nil)
            }
            //벽걸이 TV처럼 얇은 가구는 스캔 오차로 중심이 벽 바깥쪽에 있을 수 있으므로
            //가구 중심이 벽 두께 안에 있으면 방 가운데 쪽으로 밀어냄
            if penetration.side != nil, abs(simd_dot(furniture.center - wall.center, wall.normal)) < wall.halfThickness {
                let side: Float = simd_dot(roomCenter - wall.center, wall.normal) >= 0 ? 1 : -1
                penetration = FurnitureCollision.penetration(of: furniture, into: wall, side: side) ?? penetration
            }
            return WallContact(allowedDepth: penetration.depth, side: penetration.side)
        }
    }

    //벽에 겹친 만큼 벽 밖으로 밀어낸 위치
    //tightensContacts: 옮기는 중에는 벽에서 멀어진 만큼 허용 깊이를 줄임 (돌리는 중에는 처음 위치를 기준으로 계속 계산하므로 줄이지 않음)
    func resolvedPosition(_ position: SIMD2<Float>, of id: UUID, node: SCNNode, tightensContacts: Bool = true) -> SIMD2<Float> {
        guard wallContacts.count == layer.walls.count else { return position }
        var position = position

        //벽 모서리처럼 두 벽에 함께 닿으면 한 번에 다 밀어내지 못하므로 몇 번 반복
        for _ in 0..<3 {
            var isPushed = false
            for (index, wall) in layer.walls.enumerated() {
                let contact = wallContacts[index]
                guard let penetration = FurnitureCollision.penetration(of: footprint(of: id, node: node, at: position), into: wall, side: contact.side) else { continue }
                let excess = penetration.depth - contact.allowedDepth
                if excess > 1e-4 {
                    position += penetration.direction * excess
                    isPushed = true
                }
            }
            if !isPushed { break }
        }

        //벽에서 멀어진 만큼 허용하는 깊이를 줄여서 다시 벽 안으로 들어가지 못하게 함
        guard tightensContacts else { return position }
        let furniture = footprint(of: id, node: node, at: position)
        for (index, wall) in layer.walls.enumerated() {
            let depth = FurnitureCollision.penetration(of: furniture, into: wall, side: wallContacts[index].side)?.depth ?? 0
            wallContacts[index].allowedDepth = min(wallContacts[index].allowedDepth, max(depth, 0))
            if depth <= 0 {
                wallContacts[index].side = nil
            }
        }
        return position
    }
}

// MARK: - Helpers
private extension FurnitureEditor {
    func isMoved(_ id: UUID) -> Bool {
        guard let node = layer.nodes[id], let original = layer.originalTransforms[id] else { return false }
        return node.simdTransform.floats != original.floats
    }

    //움직임이 끝나면 최종 위치를 저장 - 원래 위치와 같으면 저장된 값을 지움
    func commit() {
        guard let id = selectedID, let node = layer.nodes[id] else { return }
        let moved = isMoved(id)
        draft.setFurnitureTransform(moved ? node.simdTransform : nil, for: id)
        isSelectedMoved = moved
    }

    //선택된 가구를 감싸는 반투명 박스와 테두리 선
    //RoomPalette의 재질은 모든 가구가 함께 쓰므로 하이라이트용 재질을 따로 만듦
    static func makeHighlight(size: SIMD3<Float>) -> SCNNode {
        let extent = simd_max(size, SIMD3(repeating: 0.05)) + 0.04
        let color = UIColor(red: 0.25, green: 0.55, blue: 1, alpha: 1)

        let fill = SCNMaterial()
        fill.lightingModel = .constant
        fill.diffuse.contents = color.withAlphaComponent(0.18)
        fill.writesToDepthBuffer = false

        let box = SCNBox(width: CGFloat(extent.x), height: CGFloat(extent.y), length: CGFloat(extent.z), chamferRadius: 0)
        box.materials = [fill]

        let node = SCNNode(geometry: box)
        node.name = "FurnitureHighlight"
        node.castsShadow = false
        node.renderingOrder = 100
        node.addChildNode(outlineNode(extent: extent, color: color))
        return node
    }

    static func outlineNode(extent: SIMD3<Float>, color: UIColor) -> SCNNode {
        let half = extent / 2
        var corners: [SCNVector3] = []
        for x in [-half.x, half.x] {
            for y in [-half.y, half.y] {
                for z in [-half.z, half.z] {
                    corners.append(SCNVector3(x, y, z))
                }
            }
        }
        //꼭짓점 번호: x가 4, y가 2, z가 1의 자리 - 한 축만 다른 두 꼭짓점을 이음
        let edges: [UInt16] = [
            0, 1, 2, 3, 4, 5, 6, 7,
            0, 2, 1, 3, 4, 6, 5, 7,
            0, 4, 1, 5, 2, 6, 3, 7
        ]
        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: corners)],
            elements: [SCNGeometryElement(indices: edges, primitiveType: .line)]
        )
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.castsShadow = false
        node.renderingOrder = 101
        return node
    }
}
