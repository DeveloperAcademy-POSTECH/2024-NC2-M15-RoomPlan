//
//  SCNGeometry+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SceneKit
import simd

//기기에서 SCNScene을 USDZ로 내보낼 때(USDKit) 발생하는 문제들을 피하기 위한 Extension
//- 요소(면 그룹)마다 재질이 없으면 크래시가 남
//- SCNCylinder, SCNShape는 내보낸 파일에서 사라지므로 직접 만든 메시를 사용해야 함
extension SCNGeometry {
    //요소 개수만큼 같은 재질을 넣음
    func setMaterial(_ material: SCNMaterial) {
        materials = Array(repeating: material, count: max(elementCount, 1))
    }

    //x, z 평면의 다각형을 위아래로 두께만큼 돌출시킨 지오메트리 (오목한 다각형도 가능)
    //smoothSides가 true이면 옆면을 둥글게 보이도록 꼭짓점마다 법선을 보간함 (원기둥 등)
    static func extrudedPolygon(_ polygon: [SIMD2<Float>], top: Float, thickness: Float, smoothSides: Bool = false) -> SCNGeometry {
        //반시계 방향(x, z 평면 기준)으로 정렬
        let points = signedArea(polygon) < 0 ? polygon.reversed() : polygon
        let bottom = top - thickness

        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt32] = []

        func addVertex(_ point: SIMD2<Float>, _ y: Float, normal: SIMD3<Float>) -> UInt32 {
            vertices.append(SCNVector3(point.x, y, point.y))
            normals.append(SCNVector3(normal))
            return UInt32(vertices.count - 1)
        }

        //윗면은 위에서 봤을 때 앞면이 되도록 삼각형 순서를 뒤집음
        let triangles = triangulate(points)
        let topIndices = points.map { addVertex($0, top, normal: [0, 1, 0]) }
        let bottomIndices = points.map { addVertex($0, bottom, normal: [0, -1, 0]) }
        for triangle in stride(from: 0, to: triangles.count, by: 3) {
            let (a, b, c) = (triangles[triangle], triangles[triangle + 1], triangles[triangle + 2])
            indices += [topIndices[a], topIndices[c], topIndices[b]]
            indices += [bottomIndices[a], bottomIndices[b], bottomIndices[c]]
        }

        //옆면
        let edgeNormals = points.indices.map { index -> SIMD3<Float> in
            let direction = points[(index + 1) % points.count] - points[index]
            guard simd_length(direction) > 0.0001 else { return .zero }
            return simd_normalize(SIMD3<Float>(direction.y, 0, -direction.x))
        }
        func vertexNormal(_ index: Int, fallback: SIMD3<Float>) -> SIMD3<Float> {
            guard smoothSides else { return fallback }
            let sum = edgeNormals[(index + points.count - 1) % points.count] + edgeNormals[index]
            return simd_length(sum) > 0.0001 ? simd_normalize(sum) : fallback
        }
        for index in points.indices where edgeNormals[index] != .zero {
            let next = (index + 1) % points.count
            let normal = edgeNormals[index]
            let a = addVertex(points[index], top, normal: vertexNormal(index, fallback: normal))
            let b = addVertex(points[next], top, normal: vertexNormal(next, fallback: normal))
            let c = addVertex(points[next], bottom, normal: vertexNormal(next, fallback: normal))
            let d = addVertex(points[index], bottom, normal: vertexNormal(index, fallback: normal))
            indices += [a, b, c, a, c, d]
        }

        return SCNGeometry(
            sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
    }
}

private extension SCNGeometry {
    static func signedArea(_ polygon: [SIMD2<Float>]) -> Float {
        var area: Float = 0
        for index in polygon.indices {
            let current = polygon[index]
            let next = polygon[(index + 1) % polygon.count]
            area += current.x * next.y - next.x * current.y
        }
        return area / 2
    }

    static func cross(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        a.x * b.y - a.y * b.x
    }

    static func contains(_ point: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>, _ c: SIMD2<Float>) -> Bool {
        cross(b - a, point - a) > 0 && cross(c - b, point - b) > 0 && cross(a - c, point - c) > 0
    }

    //반시계 방향 다각형을 귀 자르기(ear clipping) 방식으로 삼각형들로 나눔
    static func triangulate(_ polygon: [SIMD2<Float>]) -> [Int] {
        var remaining = Array(polygon.indices)
        var triangles: [Int] = []

        while remaining.count > 3 {
            var clipped = false
            for position in remaining.indices {
                let a = remaining[(position + remaining.count - 1) % remaining.count]
                let b = remaining[position]
                let c = remaining[(position + 1) % remaining.count]
                guard cross(polygon[b] - polygon[a], polygon[c] - polygon[b]) > 0 else { continue }
                let blocked = remaining.contains { other in
                    other != a && other != b && other != c && contains(polygon[other], polygon[a], polygon[b], polygon[c])
                }
                guard !blocked else { continue }
                triangles += [a, b, c]
                remaining.remove(at: position)
                clipped = true
                break
            }
            //다각형이 꼬여 있어서 더 이상 자를 수 없으면 남은 부분은 부채꼴로 나눔
            if !clipped {
                for index in 1..<(remaining.count - 1) {
                    triangles += [remaining[0], remaining[index], remaining[index + 1]]
                }
                return triangles
            }
        }

        return triangles + remaining
    }
}
