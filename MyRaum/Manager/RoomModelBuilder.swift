//
//  RoomModelBuilder.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SceneKit
import simd

//3D 모델에 사용하는 단색 재질 - 하얀 모형처럼 보이도록 밝은 회색 계열로 구성
enum RoomPalette {
    static let wall = material("wall", white: 0.97)
    static let furniture = material("furniture", white: 0.94)
    static let detail = material("detail", white: 0.80)
    static let dark = material("dark", white: 0.32)
    static let floor = material("floor", white: 0.62)
    static let base = material("base", white: 0.42)
    
    private static let all = [wall, furniture, detail, dark, floor, base]
    
    private static func material(_ name: String, white: CGFloat) -> SCNMaterial {
        let material = SCNMaterial()
        material.name = name
        material.lightingModel = .lambert
        material.diffuse.contents = UIColor(white: white, alpha: 1)
        return material
    }
    
    //USDZ로 저장했다가 다시 불러오면 색 공간 변환 때문에 색이 밝아지므로
    //재질 이름으로 원래 재질을 찾아서 다시 적용
    static func restore(in scene: SCNScene) {
        scene.rootNode.enumerateHierarchy { node, _ in
            guard let geometry = node.geometry else { return }
            geometry.materials = geometry.materials.map { material in
                all.first { $0.name == material.name } ?? material
            }
        }
    }
}

//RoomLayout으로 만든 3D 공간과 가구 배치 편집에 필요한 정보
struct RoomModel {
    let scene: SCNScene
    let furniture: FurnitureLayer
}

//RoomLayout으로 벽, 바닥, 가구가 있는 3D 공간을 만드는 클래스
enum RoomModelBuilder {
    static let wallThickness: Float = 0.12

    static func makeModel(from layout: RoomLayout) -> RoomModel {
        let scene = SCNScene()
        let root = SCNNode()
        root.name = "Room"
        scene.rootNode.addChildNode(root)

        let floorY = floorHeight(of: layout)
        let footprint = floorPolygon(of: layout, floorY: floorY)
        if footprint.count >= 3 {
            if let base = baseNode(footprint, floorY: floorY) {
                root.addChildNode(base)
            }
            root.addChildNode(floorNode(footprint, floorY: floorY))
        }

        for wall in layout.walls {
            root.addChildNode(wallNode(wall, openings: openings(of: wall, in: layout)))
        }

        //USDZ로 내보내면 노드 이름이 바뀔 수 있으므로 이름 대신 가구 ID로 노드를 찾을 수 있게 보관
        var furnitureNodes: [UUID: SCNNode] = [:]
        for object in layout.objects {
            let node = FurnitureModelBuilder.makeNode(for: object, in: layout)
            root.addChildNode(node)
            furnitureNodes[object.id] = node
        }

        let (minimum, maximum) = movableArea(of: layout, footprint: footprint)
        let furniture = FurnitureLayer(
            nodes: furnitureNodes,
            originalTransforms: Dictionary(layout.objects.map { ($0.id, $0.transform) }, uniquingKeysWith: { first, _ in first }),
            dimensions: Dictionary(layout.objects.map { ($0.id, $0.dimensions) }, uniquingKeysWith: { first, _ in first }),
            floorY: floorY,
            minimum: minimum,
            maximum: maximum,
            walls: layout.walls.compactMap { WallFootprint($0, thickness: wallThickness) }
        )

        return RoomModel(scene: scene, furniture: furniture)
    }
}

extension RoomModelBuilder {
    //USDZ로 내보낼 모델에서 SCNBox의 둥근 모서리를 없앰
    static func removeRoundedEdges(in scene: SCNScene) {
        scene.rootNode.enumerateHierarchy { node, _ in
            (node.geometry as? SCNBox)?.chamferRadius = 0
        }
    }
}

// MARK: - Floor
private extension RoomModelBuilder {
    //벽의 아래쪽 높이를 바닥 높이로 사용
    static func floorHeight(of layout: RoomLayout) -> Float {
        if !layout.walls.isEmpty {
            return layout.walls.map { $0.transform.position.y - $0.dimensions.y / 2 }.min() ?? 0
        }
        if !layout.objects.isEmpty {
            return layout.objects.map { $0.transform.position.y - $0.dimensions.y / 2 }.min() ?? 0
        }
        return 0
    }

    //월드 좌표계의 x, z 평면에서 본 바닥 다각형
    static func floorPolygon(of layout: RoomLayout, floorY: Float) -> [SIMD2<Float>] {
        if let floor = layout.floors.max(by: { $0.dimensions.x * $0.dimensions.y < $1.dimensions.x * $1.dimensions.y }),
           let polygon = horizontalPolygon(of: floor) {
            return polygon
        }

        //바닥 정보가 없으면 벽 끝점들을 감싸는 다각형으로 대신함
        let endpoints = layout.walls.flatMap { wall -> [SIMD2<Float>] in
            let half = wall.dimensions.x / 2
            return [-half, half].map { x in
                let point = wall.transform * SIMD4<Float>(x, 0, 0, 1)
                return SIMD2(point.x, point.z)
            }
        }
        return convexHull(endpoints)
    }

    //바닥 꼭짓점이 로컬 좌표의 어느 평면에 있는지 문서에 명시되어 있지 않으므로
    //월드 좌표로 변환했을 때 수평이 되는 경우를 선택함
    static func horizontalPolygon(of floor: RoomLayout.Floor) -> [SIMD2<Float>]? {
        let size = floor.dimensions / 2
        let candidates: [[SIMD3<Float>]] = floor.corners.count >= 3
            ? [floor.corners, floor.corners.map { SIMD3($0.x, $0.z, $0.y) }]
            : [
                [SIMD3(-size.x, -size.y, 0), SIMD3(size.x, -size.y, 0), SIMD3(size.x, size.y, 0), SIMD3(-size.x, size.y, 0)],
                [SIMD3(-size.x, 0, -size.z), SIMD3(size.x, 0, -size.z), SIMD3(size.x, 0, size.z), SIMD3(-size.x, 0, size.z)]
            ]

        let best = candidates
            .map { corners in corners.map { floor.transform * SIMD4<Float>($0, 1) } }
            .filter { points in polygonArea(points.map { SIMD2($0.x, $0.z) }) > 0.5 }
            .min { verticalSpread($0) < verticalSpread($1) }

        return best?.map { SIMD2($0.x, $0.z) }
    }

    static func verticalSpread(_ points: [SIMD4<Float>]) -> Float {
        let ys = points.map(\.y)
        return (ys.max() ?? 0) - (ys.min() ?? 0)
    }

    static func polygonArea(_ points: [SIMD2<Float>]) -> Float {
        guard points.count >= 3 else { return 0 }
        var area: Float = 0
        for index in points.indices {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            area += current.x * next.y - next.x * current.y
        }
        return abs(area) / 2
    }

    static func convexHull(_ points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        let sorted = points.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
        guard sorted.count >= 3 else { return sorted }

        func cross(_ o: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }

        var lower: [SIMD2<Float>] = []
        for point in sorted {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], point) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }
        var upper: [SIMD2<Float>] = []
        for point in sorted.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], point) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }
        return Array(lower.dropLast() + upper.dropLast())
    }

    //가구를 바닥 밖으로 너무 멀리 옮기지 않도록 제한하는 x, z 범위
    //원래 가구 위치도 범위에 넣어서 드래그를 시작할 때 가구가 튀지 않게 함
    static func movableArea(of layout: RoomLayout, footprint: [SIMD2<Float>]) -> (SIMD2<Float>, SIMD2<Float>) {
        let points = footprint + layout.objects.map { SIMD2($0.transform.position.x, $0.transform.position.z) }
        guard let first = points.first else {
            return (SIMD2(repeating: -1), SIMD2(repeating: 1))
        }
        let margin: Float = 0.3
        let minimum = points.reduce(first) { simd_min($0, $1) }
        let maximum = points.reduce(first) { simd_max($0, $1) }
        return (minimum - margin, maximum + margin)
    }

    static func slabNode(_ polygon: [SIMD2<Float>], top: Float, thickness: Float, material: SCNMaterial) -> SCNNode {
        let geometry = SCNGeometry.extrudedPolygon(polygon, top: top, thickness: thickness)
        geometry.setMaterial(material)
        return SCNNode(geometry: geometry)
    }
    
    static func floorNode(_ footprint: [SIMD2<Float>], floorY: Float) -> SCNNode {
        let node = slabNode(footprint, top: floorY, thickness: 0.04, material: RoomPalette.floor)
        node.name = "Floor"
        return node
    }
    
    //바닥 아래에 깔리는 모서리가 둥근 받침
    //바닥 다각형에 둥근 테두리를 합쳐서 바깥으로 넓힌 모양을 만듦
    static func baseNode(_ footprint: [SIMD2<Float>], floorY: Float) -> SCNNode? {
        let path = CGMutablePath()
        path.addLines(between: footprint.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) })
        path.closeSubpath()
        
        let margin: CGFloat = 0.35
        let expanded = path.union(path.copy(strokingWithWidth: margin * 2, lineCap: .round, lineJoin: .round, miterLimit: 10))
        guard let outline = expanded.flattenedPolygons().max(by: { polygonArea($0) < polygonArea($1) }) else { return nil }
        
        let node = slabNode(outline, top: floorY - 0.03, thickness: 0.12, material: RoomPalette.base)
        node.name = "Base"
        return node
    }
}

// MARK: - Wall
private extension RoomModelBuilder {
    struct Hole {
        var minX: Float
        var maxX: Float
        var minY: Float
        var maxY: Float
        var kind: RoomLayout.Opening.Kind
    }

    static func openings(of wall: RoomLayout.Wall, in layout: RoomLayout) -> [RoomLayout.Opening] {
        let inverse = wall.transform.inverse
        let halfWidth = wall.dimensions.x / 2
        let halfHeight = wall.dimensions.y / 2

        return layout.openings.filter { opening in
            if let parentID = opening.parentID {
                return parentID == wall.id
            }
            //부모 벽 정보가 없으면 벽 평면 위에 있는 문, 창문을 찾음
            let local = (inverse * opening.transform).position
            return abs(local.z) < 0.3 && abs(local.x) < halfWidth + 0.1 && abs(local.y) < halfHeight + 0.1
        }
    }

    //문, 창문 자리를 비워두고 나머지 부분을 블록으로 채워서 벽을 만듦
    static func wallNode(_ wall: RoomLayout.Wall, openings: [RoomLayout.Opening]) -> SCNNode {
        let node = SCNNode()
        node.name = "Wall"
        node.simdTransform = wall.transform

        let thickness = wallThickness
        //벽이 만나는 모서리가 비지 않도록 두께만큼 길게 만듦
        let halfLength = wall.dimensions.x / 2 + thickness / 2
        let halfHeight = wall.dimensions.y / 2
        let front = thickness / 2

        let holes = mergedHoles(of: wall, openings: openings, halfLength: halfLength, halfHeight: halfHeight)

        var cursor = -halfLength
        for hole in holes {
            if hole.minX > cursor {
                node.addBlock(min: [cursor, -halfHeight, -front], max: [hole.minX, halfHeight, front], material: RoomPalette.wall)
            }
            if hole.maxY < halfHeight - 0.01 {
                node.addBlock(min: [hole.minX, hole.maxY, -front], max: [hole.maxX, halfHeight, front], material: RoomPalette.wall)
            }
            if hole.minY > -halfHeight + 0.01 {
                node.addBlock(min: [hole.minX, -halfHeight, -front], max: [hole.maxX, hole.minY, front], material: RoomPalette.wall)
            }
            addFilling(to: node, for: hole)
            cursor = max(cursor, hole.maxX)
        }
        if cursor < halfLength {
            node.addBlock(min: [cursor, -halfHeight, -front], max: [halfLength, halfHeight, front], material: RoomPalette.wall)
        }

        return node
    }

    //벽의 로컬 좌표로 변환한 구멍들을 x축 기준으로 정렬하고 겹치는 구멍은 하나로 합침
    static func mergedHoles(of wall: RoomLayout.Wall, openings: [RoomLayout.Opening], halfLength: Float, halfHeight: Float) -> [Hole] {
        let inverse = wall.transform.inverse
        var holes: [Hole] = []
        for opening in openings {
            let center: SIMD3<Float> = (inverse * opening.transform).position
            let size: SIMD3<Float> = opening.dimensions / 2
            let minX: Float = max(center.x - size.x, -halfLength)
            let maxX: Float = min(center.x + size.x, halfLength)
            let maxY: Float = min(center.y + size.y, halfHeight)
            var minY: Float = max(center.y - size.y, -halfHeight)
            if case .window = opening.kind {} else {
                //문과 통로는 바닥까지 뚫려 있음
                minY = -halfHeight
            }
            if maxX - minX > 0.05 && maxY - minY > 0.05 {
                holes.append(Hole(minX: minX, maxX: maxX, minY: minY, maxY: maxY, kind: opening.kind))
            }
        }
        holes.sort { $0.minX < $1.minX }

        var merged: [Hole] = []
        for hole in holes {
            if var last = merged.last, hole.minX < last.maxX {
                last.maxX = max(last.maxX, hole.maxX)
                last.minY = min(last.minY, hole.minY)
                last.maxY = max(last.maxY, hole.maxY)
                merged[merged.count - 1] = last
            } else {
                merged.append(hole)
            }
        }
        return merged
    }

    //닫힌 문은 문짝, 열린 문은 90도 열린 문짝을 채움 (창문과 통로는 뚫린 채로 둠)
    static func addFilling(to node: SCNNode, for hole: Hole) {
        switch hole.kind {
        case .door(let isOpen):
            let width = hole.maxX - hole.minX
            if isOpen {
                node.addBlock(min: [hole.minX + 0.01, hole.minY, 0], max: [hole.minX + 0.05, hole.maxY - 0.02, width - 0.04], material: RoomPalette.detail)
            } else {
                node.addBlock(min: [hole.minX + 0.01, hole.minY, -0.02], max: [hole.maxX - 0.01, hole.maxY - 0.01, 0.02], material: RoomPalette.detail)
            }
        case .window, .opening:
            break
        }
    }
}

// MARK: - Helpers
extension SCNNode {
    //최소, 최대 좌표로 위치와 크기를 지정하는 블록
    @discardableResult
    func addBlock(min lower: SIMD3<Float>, max upper: SIMD3<Float>, material: SCNMaterial, chamfer: Float = 0) -> SCNNode {
        let size = simd_max(upper - lower, SIMD3(repeating: 0.002))
        let box = SCNBox(
            width: CGFloat(size.x),
            height: CGFloat(size.y),
            length: CGFloat(size.z),
            chamferRadius: CGFloat(Swift.min(chamfer, size.min() / 2))
        )
        box.setMaterial(material)
        let node = SCNNode(geometry: box)
        node.simdPosition = (lower + upper) / 2
        addChildNode(node)
        return node
    }

    //가로, 세로 반지름을 다르게 하면 타원 기둥이 됨
    @discardableResult
    func addCylinder(center: SIMD3<Float>, radiusX: Float, radiusZ: Float, height: Float, material: SCNMaterial) -> SCNNode {
        let segments = 36
        let ellipse = (0..<segments).map { index -> SIMD2<Float> in
            let angle = Float(index) / Float(segments) * 2 * .pi
            return SIMD2(cos(angle) * radiusX, sin(angle) * radiusZ)
        }
        let thickness = Swift.max(height, 0.002)
        let geometry = SCNGeometry.extrudedPolygon(ellipse, top: thickness / 2, thickness: thickness, smoothSides: true)
        geometry.setMaterial(material)
        let node = SCNNode(geometry: geometry)
        node.simdPosition = center
        addChildNode(node)
        return node
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
}
