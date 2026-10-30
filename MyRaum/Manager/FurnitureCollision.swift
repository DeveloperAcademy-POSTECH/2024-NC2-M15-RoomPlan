//
//  FurnitureCollision.swift
//  MyRaum
//
//  Created by Yune Cho on 10/30/26.
//

import simd

//위에서 내려다본 벽의 모양 (x, z 평면의 직사각형)
struct WallFootprint {
    var center: SIMD2<Float>
    //벽의 가로 방향 (단위 벡터)
    var axis: SIMD2<Float>
    var halfLength: Float
    var halfThickness: Float

    //벽의 법선 방향
    var normal: SIMD2<Float> {
        SIMD2(-axis.y, axis.x)
    }

    //RoomModelBuilder.wallNode와 같은 크기 - 벽이 만나는 모서리가 비지 않도록 두께만큼 길게 만듦
    init?(_ wall: RoomLayout.Wall, thickness: Float) {
        let direction = SIMD2(wall.transform.columns.0.x, wall.transform.columns.0.z)
        guard simd_length(direction) > 1e-4 else { return nil }
        center = SIMD2(wall.transform.position.x, wall.transform.position.z)
        axis = simd_normalize(direction)
        halfLength = wall.dimensions.x / 2 + thickness / 2
        halfThickness = thickness / 2
    }
}

//위에서 내려다본 가구의 바닥면 (가구 방향에 맞춰 회전된 직사각형)
struct FurnitureFootprint {
    var center: SIMD2<Float>
    var axisX: SIMD2<Float>
    var axisZ: SIMD2<Float>
    var halfX: Float
    var halfZ: Float
}

//가구가 벽을 통과하지 못하게 하는 간단한 충돌 검사
//문, 창문 자리도 벽으로 보고, 가구끼리의 충돌은 검사하지 않음
enum FurnitureCollision {
    //가구가 벽에 겹친 정도
    struct Penetration {
        //겹친 깊이
        var depth: Float
        //가구를 벽 밖으로 밀어내는 방향 (단위 벡터)
        var direction: SIMD2<Float>
        //벽의 법선 방향으로 밀어낼 때 가구가 있는 쪽 (1 또는 -1) - 벽 끝에서 가로 방향으로 밀어내면 nil
        var side: Float?
    }

    //두 직사각형이 겹치면 가장 적게 밀어내는 방향과 깊이를 구함 (분리축 검사)
    //벽 옆면에 닿으면 벽의 법선 방향으로, 벽 끝에 닿으면 벽의 가로 방향으로 밀어냄
    //side: 벽의 어느 쪽으로 밀어낼지 정해둔 값 - 처음부터 벽에 묻혀 있던 가구가 벽 반대편으로 밀려나지 않게 할 때 사용
    static func penetration(of furniture: FurnitureFootprint, into wall: WallFootprint, side: Float? = nil) -> Penetration? {
        let offset = furniture.center - wall.center

        //가구의 축 방향으로도 떨어져 있으면 겹치지 않음
        for axis in [furniture.axisX, furniture.axisZ] {
            let furnitureRadius = radius(of: furniture, along: axis)
            let wallRadius = wall.halfLength * abs(simd_dot(wall.axis, axis)) + wall.halfThickness * abs(simd_dot(wall.normal, axis))
            if abs(simd_dot(offset, axis)) >= furnitureRadius + wallRadius {
                return nil
            }
        }

        let normalDistance = simd_dot(offset, wall.normal)
        let normalSide = side ?? (normalDistance >= 0 ? 1 : -1)
        //가구 중심이 정해둔 쪽의 반대편에 있으면 그만큼 더 깊이 겹친 것으로 봄
        let normalDepth = radius(of: furniture, along: wall.normal) + wall.halfThickness - normalSide * normalDistance
        let axisDistance = simd_dot(offset, wall.axis)
        let axisDepth = radius(of: furniture, along: wall.axis) + wall.halfLength - abs(axisDistance)
        guard normalDepth > 0, axisDepth > 0 else { return nil }

        if normalDepth <= axisDepth {
            return Penetration(depth: normalDepth, direction: wall.normal * normalSide, side: normalSide)
        }
        return Penetration(depth: axisDepth, direction: wall.axis * (axisDistance >= 0 ? 1 : -1), side: nil)
    }

    static func radius(of furniture: FurnitureFootprint, along axis: SIMD2<Float>) -> Float {
        furniture.halfX * abs(simd_dot(furniture.axisX, axis)) + furniture.halfZ * abs(simd_dot(furniture.axisZ, axis))
    }
}
