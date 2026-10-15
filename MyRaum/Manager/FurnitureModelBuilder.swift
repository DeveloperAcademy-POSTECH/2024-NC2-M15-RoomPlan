//
//  FurnitureModelBuilder.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SceneKit
import simd
import RoomPlan

//RoomPlan이 인식한 가구의 종류, 형태 정보(attributes), 크기로 가구 모양을 만드는 클래스
//가구는 바운딩 박스 안에서 "뒤쪽이 -z, 가로가 x"인 기준 방향으로 만든 뒤 실제 방향으로 회전시킴
enum FurnitureModelBuilder {
    static func makeNode(for object: RoomLayout.Object, in layout: RoomLayout) -> SCNNode {
        let node = SCNNode()
        node.name = object.category.rawValue
        node.simdTransform = object.transform

        let side = backSide(of: object, in: layout)
        let size = side.swapsAxes
            ? SIMD3(object.dimensions.z, object.dimensions.y, object.dimensions.x)
            : object.dimensions

        let content = SCNNode()
        content.simdOrientation = simd_quatf(angle: side.yaw, axis: [0, 1, 0])
        build(object.category, attributes: object.attributes, size: size, into: content)
        node.addChildNode(content)

        return node
    }
}

//가구가 작게 인식되면 계산된 범위의 아래, 위가 뒤집힐 수 있으므로
//이 파일에서는 Float 범위를 만들 때 크래시 대신 두 값을 정렬해서 사용
fileprivate func ... (lhs: Float, rhs: Float) -> ClosedRange<Float> {
    ClosedRange(uncheckedBounds: (Swift.min(lhs, rhs), Swift.max(lhs, rhs)))
}

// MARK: - Orientation
private extension FurnitureModelBuilder {
    //가구의 뒤쪽이 바운딩 박스의 어느 면인지
    enum Side: CaseIterable {
        case negativeZ, positiveZ, negativeX, positiveX

        var normal: SIMD3<Float> {
            switch self {
            case .negativeZ: [0, 0, -1]
            case .positiveZ: [0, 0, 1]
            case .negativeX: [-1, 0, 0]
            case .positiveX: [1, 0, 0]
            }
        }

        //기준 방향의 뒤쪽(-z)을 이 면으로 돌리는 회전 각도
        var yaw: Float {
            switch self {
            case .negativeZ: 0
            case .positiveZ: .pi
            case .negativeX: .pi / 2
            case .positiveX: -.pi / 2
            }
        }

        var swapsAxes: Bool {
            self == .negativeX || self == .positiveX
        }
    }

    //RoomPlan 문서에 가구의 앞쪽 방향이 명시되어 있지 않으므로
    //의자는 테이블 반대쪽, 그 외 가구는 가까운 벽 쪽을 뒤쪽으로 판단함
    static func backSide(of object: RoomLayout.Object, in layout: RoomLayout) -> Side {
        let size = object.dimensions
        let alongZ: [Side] = [.negativeZ, .positiveZ]
        let alongX: [Side] = [.negativeX, .positiveX]

        let candidates: [Side]
        switch object.category {
        case .table, .bathtub:
            return .negativeZ
        case .bed, .stairs:
            //침대 머리, 계단 방향은 긴 쪽 축에 있음
            candidates = size.z >= size.x ? alongZ : alongX
        case .sofa, .storage, .television, .fireplace:
            //등받이, 뒷면은 짧은 쪽 축에 있음
            candidates = size.z <= size.x ? alongZ : alongX
        case .chair:
            if let parentID = object.parentID,
               let table = layout.objects.first(where: { $0.id == parentID }) {
                return side(of: object, facingAwayFrom: table.transform.position)
            }
            candidates = Side.allCases
        default:
            candidates = Side.allCases
        }

        return nearestWallSide(of: object, candidates: candidates, walls: layout.walls) ?? candidates[0]
    }

    static func worldNormal(of side: Side, in object: RoomLayout.Object) -> SIMD3<Float> {
        let normal = object.transform * SIMD4<Float>(side.normal, 0)
        return simd_normalize(SIMD3(normal.x, 0, normal.z))
    }

    static func side(of object: RoomLayout.Object, facingAwayFrom point: SIMD3<Float>) -> Side {
        var away = object.transform.position - point
        away.y = 0
        return Side.allCases.max { dot(worldNormal(of: $0, in: object), away) < dot(worldNormal(of: $1, in: object), away) } ?? .negativeZ
    }

    static func nearestWallSide(of object: RoomLayout.Object, candidates: [Side], walls: [RoomLayout.Wall]) -> Side? {
        guard !walls.isEmpty else { return nil }
        let center = object.transform.position

        let distances = candidates.map { side -> (Side, Float) in
            let halfExtent = side.swapsAxes ? object.dimensions.x / 2 : object.dimensions.z / 2
            let point = center + worldNormal(of: side, in: object) * halfExtent
            let distance = walls.map { distanceToWall(point, $0) }.min() ?? .infinity
            return (side, distance)
        }

        guard let nearest = distances.min(by: { $0.1 < $1.1 }), nearest.1 < 0.7 else { return nil }
        return nearest.0
    }

    static func distanceToWall(_ point: SIMD3<Float>, _ wall: RoomLayout.Wall) -> Float {
        let center = wall.transform.position
        let axis = simd_normalize(SIMD3(wall.transform.columns.0.x, 0, wall.transform.columns.0.z))
        var offset = point - center
        offset.y = 0
        let projection = simd_clamp(dot(offset, axis), -wall.dimensions.x / 2, wall.dimensions.x / 2)
        return simd_length(offset - axis * projection)
    }
}

// MARK: - Shapes
private extension FurnitureModelBuilder {
    static func build(_ category: FurnitureCategory, attributes: FurnitureAttributes, size: SIMD3<Float>, into node: SCNNode) {
        let shape = Shape(size: size, node: node)
        switch category {
        case .chair: shape.chair(attributes)
        case .sofa: shape.sofa(attributes)
        case .table: shape.table(attributes)
        case .storage: shape.storage(attributes)
        case .bed: shape.bed()
        case .refrigerator: shape.refrigerator()
        case .stove: shape.stove()
        case .oven: shape.oven()
        case .dishwasher: shape.dishwasher()
        case .sink: shape.sink()
        case .washerDryer: shape.washerDryer()
        case .toilet: shape.toilet()
        case .bathtub: shape.bathtub()
        case .fireplace: shape.fireplace()
        case .television: shape.television()
        case .stairs: shape.stairs()
        }
    }

    //기준 방향의 바운딩 박스 - 중심이 원점, 뒤쪽이 -z, 바닥이 bottom
    struct Shape {
        let width: Float
        let height: Float
        let depth: Float
        let node: SCNNode

        init(size: SIMD3<Float>, node: SCNNode) {
            width = max(size.x, 0.05)
            height = max(size.y, 0.05)
            depth = max(size.z, 0.05)
            self.node = node
        }

        var left: Float { -width / 2 }
        var right: Float { width / 2 }
        var back: Float { -depth / 2 }
        var front: Float { depth / 2 }
        var bottom: Float { -height / 2 }
        var top: Float { height / 2 }

        func block(_ x: ClosedRange<Float>, _ y: ClosedRange<Float>, _ z: ClosedRange<Float>, _ material: SCNMaterial = RoomPalette.furniture, chamfer: Float = 0) {
            node.addBlock(min: [x.lowerBound, y.lowerBound, z.lowerBound], max: [x.upperBound, y.upperBound, z.upperBound], material: material, chamfer: chamfer)
        }

        //가로 방향으로 나눠진 쿠션들
        func cushions(_ x: ClosedRange<Float>, _ y: ClosedRange<Float>, _ z: ClosedRange<Float>) {
            let span = x.upperBound - x.lowerBound
            guard span > 0.1 else { return }
            let count = max(1, Int((span / 0.65).rounded()))
            let unit = span / Float(count)
            for index in 0..<count {
                let start = x.lowerBound + unit * Float(index) + 0.01
                block(start...(start + unit - 0.02), y, z, chamfer: 0.04)
            }
        }
    }
}

// MARK: - Seating & Tables
private extension FurnitureModelBuilder.Shape {
    func chair(_ attributes: FurnitureAttributes) {
        let type = attributes.chairType ?? .unidentified
        let isStool = type == .stool
        let hasBack = isStool ? attributes.chairBack == .existing : attributes.chairBack != .missing
        let hasArms = attributes.chairArm == .existing
        let legType = attributes.chairLeg ?? (type == .swivel ? .star : .four)

        let seatTop = hasBack ? min(max(0.45, height * 0.5), height - 0.1) : height
        let seatBottom = bottom + seatTop - 0.06
        let seatX = (left * 0.94)...(right * 0.94)
        let seatZ = (back * 0.94)...(front * 0.94)

        if isStool && legType == .star {
            node.addCylinder(center: [0, seatBottom + 0.03, 0], radiusX: width * 0.45, radiusZ: depth * 0.45, height: 0.06, material: RoomPalette.furniture)
        } else {
            block(seatX, seatBottom...(bottom + seatTop), seatZ, chamfer: 0.02)
        }

        switch legType {
        case .star:
            //회전의자 - 가운데 기둥과 별 모양 다리
            node.addCylinder(center: [0, (bottom + 0.05 + seatBottom) / 2, 0], radiusX: 0.025, radiusZ: 0.025, height: seatBottom - bottom - 0.05, material: RoomPalette.detail)
            let spokeLength = min(width, depth) * 0.45
            for index in 0..<5 {
                let pivot = SCNNode()
                pivot.simdOrientation = simd_quatf(angle: Float(index) * 2 * .pi / 5, axis: [0, 1, 0])
                pivot.addBlock(min: [-0.02, bottom, 0], max: [0.02, bottom + 0.04, spokeLength], material: RoomPalette.detail)
                node.addChildNode(pivot)
            }
        default:
            let legX = seatX.upperBound - 0.03
            let legZ = seatZ.upperBound - 0.03
            for x in [-legX, legX] {
                for z in [-legZ, legZ] {
                    block((x - 0.02)...(x + 0.02), bottom...seatBottom, (z - 0.02)...(z + 0.02), RoomPalette.detail)
                }
            }
        }

        if hasBack {
            block((left * 0.9)...(right * 0.9), (bottom + seatTop)...top, (back * 0.94)...(back * 0.94 + 0.05), chamfer: 0.02)
        }

        if hasArms {
            let armY = min(bottom + seatTop + 0.22, top - 0.02)
            for x in [left * 0.94, right * 0.94 - 0.05] {
                block(x...(x + 0.05), (armY - 0.04)...armY, (back * 0.8)...(front * 0.8), chamfer: 0.015)
                block((x + 0.01)...(x + 0.04), (bottom + seatTop)...armY, (front * 0.7)...(front * 0.7 + 0.03))
            }
        }
    }

    func sofa(_ attributes: FurnitureAttributes) {
        let type = attributes.sofaType ?? .rectangular
        let seatTop = bottom + min(0.45, height * 0.6)
        let frameTop = seatTop - 0.12
        let backThickness = min(0.22, depth * 0.28)
        let armWidth = min(type == .singleSeat ? 0.15 : 0.18, width * 0.15)
        let armTop = min(top, seatTop + 0.2)
        let backRest = (back + backThickness)

        switch type {
        case .lShaped, .lShapedExtension:
            //L자형 - 등받이 쪽의 긴 부분과 +x 쪽으로 튀어나온 부분
            let mainFront = back + min(depth - 0.3, max(0.85, depth * 0.5))
            let chaiseLeft = right - min(width - 0.5, max(0.8, width * 0.35))
            let hasSideBack = type == .lShaped
            let seatRight = hasSideBack ? right - backThickness : right

            block(left...right, bottom...frameTop, back...mainFront, chamfer: 0.02)
            block(chaiseLeft...right, bottom...frameTop, mainFront...front, chamfer: 0.02)
            block(left...right, frameTop...top, back...backRest, chamfer: 0.04)
            if hasSideBack {
                block(seatRight...right, frameTop...top, backRest...front, chamfer: 0.04)
            }
            block(left...(left + armWidth), frameTop...armTop, backRest...mainFront, chamfer: 0.04)

            cushions((left + armWidth)...chaiseLeft, frameTop...seatTop, backRest...mainFront)
            cushions(chaiseLeft...seatRight, frameTop...seatTop, backRest...front)
            cushions((left + armWidth)...seatRight, seatTop...(seatTop + (top - seatTop) * 0.7), backRest...(backRest + 0.14))

        default:
            let seatLeft = left + armWidth
            let seatRight = right - armWidth
            block(left...right, bottom...frameTop, back...front, chamfer: 0.02)
            block(left...right, frameTop...top, back...backRest, chamfer: 0.04)
            block(left...seatLeft, frameTop...armTop, backRest...front, chamfer: 0.04)
            block(seatRight...right, frameTop...armTop, backRest...front, chamfer: 0.04)
            cushions(seatLeft...seatRight, frameTop...seatTop, backRest...front)
            cushions(seatLeft...seatRight, seatTop...(seatTop + (top - seatTop) * 0.7), backRest...(backRest + 0.14))
        }
    }

    func table(_ attributes: FurnitureAttributes) {
        let isCoffee = attributes.tableType == .coffee
        let topThickness: Float = isCoffee ? 0.05 : 0.035
        let underTop = top - topThickness

        switch attributes.tableShape ?? .rectangular {
        case .circularElliptic:
            node.addCylinder(center: [0, top - topThickness / 2, 0], radiusX: width / 2, radiusZ: depth / 2, height: topThickness, material: RoomPalette.furniture)
            node.addCylinder(center: [0, (bottom + underTop) / 2, 0], radiusX: 0.05, radiusZ: 0.05, height: underTop - bottom, material: RoomPalette.detail)
            node.addCylinder(center: [0, bottom + 0.015, 0], radiusX: width * 0.25, radiusZ: depth * 0.25, height: 0.03, material: RoomPalette.detail)

        case .lShaped:
            let mainFront = back + min(depth * 0.5, 0.75)
            let sideLeft = right - min(width * 0.5, 0.75)
            block(left...right, underTop...top, back...mainFront, chamfer: 0.01)
            block(sideLeft...right, underTop...top, mainFront...front, chamfer: 0.01)
            block(left...(left + 0.04), bottom...underTop, back...mainFront, RoomPalette.detail)
            block((right - 0.04)...right, bottom...underTop, back...front, RoomPalette.detail)
            block(sideLeft...(right - 0.04), bottom...underTop, (front - 0.04)...front, RoomPalette.detail)

        default:
            block(left...right, underTop...top, back...front, chamfer: 0.01)
            let legSize: Float = isCoffee ? 0.06 : 0.05
            for x in [left + 0.04, right - 0.04 - legSize] {
                for z in [back + 0.04, front - 0.04 - legSize] {
                    block(x...(x + legSize), bottom...underTop, z...(z + legSize), RoomPalette.detail)
                }
            }
            if isCoffee && height > 0.3 {
                //커피 테이블 아래 선반
                block((left + 0.06)...(right - 0.06), (bottom + 0.08)...(bottom + 0.11), (back + 0.06)...(front - 0.06))
            }
        }
    }
}

// MARK: - Storage & Bed
private extension FurnitureModelBuilder.Shape {
    func storage(_ attributes: FurnitureAttributes) {
        if attributes.storageType == .shelf {
            shelf()
        } else {
            cabinet()
        }
    }

    //뒤판과 옆판이 있고 앞이 열린 선반
    func shelf() {
        let panel: Float = 0.03
        block(left...(left + panel), bottom...top, back...front)
        block((right - panel)...right, bottom...top, back...front)
        block(left...right, (top - panel)...top, back...front)
        block(left...right, bottom...(bottom + 0.06), back...front)
        block(left...right, bottom...top, back...(back + 0.015))

        let count = max(1, Int(((height - 0.1) / 0.38).rounded()) - 1)
        let spacing = (height - 0.06 - panel) / Float(count + 1)
        for index in 1...count {
            let y = bottom + 0.06 + spacing * Float(index)
            block((left + panel)...(right - panel), (y - 0.012)...(y + 0.012), back...(front - 0.01))
        }
    }

    //문이 달린 수납장 - 낮은 수납장에는 상판을 올림
    func cabinet() {
        let hasCounter = height < 1.1
        let bodyTop = hasCounter ? top - 0.04 : top
        block((left + 0.02)...(right - 0.02), bottom...(bottom + 0.06), back...(front - 0.05), RoomPalette.detail)
        block(left...right, (bottom + 0.06)...bodyTop, back...(front - 0.02))
        if hasCounter {
            block(left...right, bodyTop...top, back...front, chamfer: 0.005)
        }
        doors(count: max(1, Int((width / 0.5).rounded())), y: (bottom + 0.08)...(bodyTop - 0.02))
    }

    func doors(count: Int, y: ClosedRange<Float>) {
        let unit = width / Float(count)
        for index in 0..<count {
            let start = left + unit * Float(index)
            block((start + 0.005)...(start + unit - 0.005), y, (front - 0.025)...front, chamfer: 0.005)
            //손잡이는 문 사이 가운데 쪽에 배치
            let handleX = index % 2 == 0 ? start + unit - 0.05 : start + 0.035
            let handleY = y.upperBound - min(0.2, (y.upperBound - y.lowerBound) * 0.3)
            block(handleX...(handleX + 0.015), (handleY - 0.06)...(handleY + 0.06), front...(front + 0.02), RoomPalette.dark)
        }
    }

    func bed() {
        let baseTop = bottom + min(0.3, height * 0.45)
        let mattressTop = min(top, baseTop + 0.22)
        let hasHeadboard = top > mattressTop + 0.15
        let headEnd = hasHeadboard ? back + 0.08 : back

        if hasHeadboard {
            block(left...right, bottom...top, back...headEnd, chamfer: 0.03)
        }
        block(left...right, bottom...baseTop, headEnd...front, RoomPalette.detail, chamfer: 0.02)
        block((left + 0.02)...(right - 0.02), baseTop...mattressTop, (headEnd + 0.02)...(front - 0.02), chamfer: 0.06)

        //발 쪽을 덮는 이불
        let blanketStart = headEnd + (front - headEnd) * 0.4
        block((left + 0.01)...(right - 0.01), (mattressTop - 0.08)...(mattressTop + 0.025), blanketStart...(front - 0.01), chamfer: 0.03)

        let pillowCount = width > 1.3 ? 2 : 1
        let pillowWidth = (width - 0.2) / Float(pillowCount)
        for index in 0..<pillowCount {
            let start = left + 0.1 + pillowWidth * Float(index)
            block((start + 0.03)...(start + pillowWidth - 0.03), mattressTop...(mattressTop + 0.1), (headEnd + 0.06)...(headEnd + 0.42), chamfer: 0.05)
        }
    }
}

// MARK: - Kitchen & Bathroom
private extension FurnitureModelBuilder.Shape {
    func refrigerator() {
        block(left...right, bottom...top, back...(front - 0.03), chamfer: 0.03)
        let split = bottom + height * 0.62
        block((left + 0.01)...(right - 0.01), bottom...(split - 0.006), (front - 0.03)...front, chamfer: 0.01)
        block((left + 0.01)...(right - 0.01), (split + 0.006)...(top - 0.01), (front - 0.03)...front, chamfer: 0.01)
        let handleX = right - 0.07
        block(handleX...(handleX + 0.02), (split + 0.05)...(split + 0.35), front...(front + 0.03), RoomPalette.detail)
        block(handleX...(handleX + 0.02), (split - 0.35)...(split - 0.05), front...(front + 0.03), RoomPalette.detail)
    }

    func stove() {
        block(left...right, bottom...(top - 0.02), back...front)
        block((left + 0.01)...(right - 0.01), (top - 0.02)...top, (back + 0.01)...(front - 0.01), RoomPalette.dark)
        let radius = min(width, depth) * 0.13
        for x in [-width / 4, width / 4] {
            for z in [-depth / 4, depth / 4] {
                node.addCylinder(center: [x, top + 0.005, z], radiusX: radius, radiusZ: radius, height: 0.01, material: RoomPalette.detail)
            }
        }
        ovenDoor()
    }

    func oven() {
        block(left...right, bottom...top, back...front, chamfer: 0.01)
        ovenDoor()
    }

    func ovenDoor() {
        block((left + width * 0.15)...(right - width * 0.15), (bottom + height * 0.2)...(bottom + height * 0.6), front...(front + 0.01), RoomPalette.dark)
        block((left + width * 0.15)...(right - width * 0.15), (bottom + height * 0.68)...(bottom + height * 0.7), front...(front + 0.03), RoomPalette.detail)
    }

    func dishwasher() {
        block(left...right, bottom...top, back...front, chamfer: 0.01)
        block((left + 0.01)...(right - 0.01), (top - 0.08)...(top - 0.02), front...(front + 0.008), RoomPalette.dark)
        block((left + width * 0.2)...(right - width * 0.2), (top - 0.12)...(top - 0.1), front...(front + 0.03), RoomPalette.detail)
    }

    //수납장 위에 개수대와 수전
    func sink() {
        cabinet()
        block((left + width * 0.2)...(right - width * 0.2), top...(top + 0.004), (back + depth * 0.25)...(front - depth * 0.2), RoomPalette.dark)
        let faucetZ = back + depth * 0.12
        node.addCylinder(center: [0, top + 0.13, faucetZ], radiusX: 0.015, radiusZ: 0.015, height: 0.26, material: RoomPalette.detail)
        block(-0.015...0.015, (top + 0.23)...(top + 0.26), faucetZ...(faucetZ + 0.15), RoomPalette.detail)
    }

    func washerDryer() {
        block(left...right, bottom...top, back...front, chamfer: 0.03)
        let radius = min(width, height) * 0.3
        let door = node.addCylinder(center: [0, bottom + height * 0.45, front + 0.012], radiusX: radius, radiusZ: radius, height: 0.024, material: RoomPalette.detail)
        door.eulerAngles.x = .pi / 2
        let glass = node.addCylinder(center: [0, bottom + height * 0.45, front + 0.026], radiusX: radius * 0.72, radiusZ: radius * 0.72, height: 0.006, material: RoomPalette.dark)
        glass.eulerAngles.x = .pi / 2
        block((left + 0.04)...(right - 0.04), (top - 0.1)...(top - 0.04), front...(front + 0.006), RoomPalette.detail)
    }

    func toilet() {
        let seatHeight = min(0.42, height * 0.6)
        block((left + width * 0.1)...(right - width * 0.1), (bottom + seatHeight)...top, back...(back + min(0.2, depth * 0.3)), chamfer: 0.03)
        let bowlCenterZ = back + depth * 0.58
        node.addCylinder(center: [0, bottom + seatHeight / 2, bowlCenterZ], radiusX: width * 0.3, radiusZ: depth * 0.3, height: seatHeight, material: RoomPalette.furniture)
        node.addCylinder(center: [0, bottom + seatHeight + 0.02, bowlCenterZ], radiusX: width * 0.42, radiusZ: depth * 0.4, height: 0.04, material: RoomPalette.furniture)
    }

    //속이 빈 욕조
    func bathtub() {
        let rim: Float = 0.08
        block(left...right, bottom...(bottom + 0.08), back...front, chamfer: 0.02)
        block(left...(left + rim), bottom...top, back...front, chamfer: 0.02)
        block((right - rim)...right, bottom...top, back...front, chamfer: 0.02)
        block(left...right, bottom...top, back...(back + rim), chamfer: 0.02)
        block(left...right, bottom...top, (front - rim)...front, chamfer: 0.02)
    }
}

// MARK: - Others
private extension FurnitureModelBuilder.Shape {
    func fireplace() {
        block(left...right, bottom...(top - 0.05), back...front)
        block((left - 0.03)...(right + 0.03), (top - 0.05)...top, back...(front + 0.03), chamfer: 0.01)
        block((left + width * 0.2)...(right - width * 0.2), (bottom + 0.05)...(bottom + height * 0.55), front...(front + 0.006), RoomPalette.dark)
    }

    //받침대가 있으면 스탠드형, 없으면 벽걸이형
    func television() {
        let panelThickness = min(depth, 0.06)
        let hasStand = depth > 0.15 && height > 0.3
        let panelBottom = hasStand ? bottom + 0.1 : bottom
        block(left...right, panelBottom...top, (-panelThickness / 2)...(panelThickness / 2), chamfer: 0.005)
        block((left + 0.015)...(right - 0.015), (panelBottom + 0.015)...(top - 0.015), (panelThickness / 2)...(panelThickness / 2 + 0.004), RoomPalette.dark)
        if hasStand {
            block((-width * 0.15)...(width * 0.15), bottom...(bottom + 0.02), (back * 0.6)...(front * 0.6), RoomPalette.detail)
            block(-0.03...0.03, bottom...panelBottom, -0.02...0.02, RoomPalette.detail)
        }
    }

    //앞에서 뒤로 올라가는 계단
    func stairs() {
        let count = max(3, Int((height / 0.18).rounded()))
        let stepHeight = height / Float(count)
        let stepDepth = depth / Float(count)
        for index in 0..<count {
            let stepFront = front - stepDepth * Float(index)
            block(left...right, bottom...(bottom + stepHeight * Float(index + 1)), (stepFront - stepDepth)...stepFront)
        }
    }
}
