//
//  FurnitureArrangement.swift
//  MyRaum
//
//  Created by Yune Cho on 10/29/26.
//

import Foundation
import simd

//사용자가 바꾼 가구 배치 - SpaceRecord.arrangementData에 JSON으로 저장
//RoomPlan 원본(roomData)은 그대로 두고, 원본으로 장면을 만든 뒤 이 배치를 가구 노드에 덮어씀
//필드를 추가할 때는 이전 데이터를 읽을 수 있도록 반드시 optional로 추가
//- 가구 목록에서 추가한 가구, Object Capture로 스캔한 가구 참조 등
struct FurnitureArrangement: Codable, Equatable {
    static let currentVersion = 1

    var version: Int = FurnitureArrangement.currentVersion
    //RoomPlan이 인식한 가구 중 원래 위치에서 옮기거나 돌린 가구
    var placements: [Placement] = []

    struct Placement: Codable, Equatable {
        //RoomLayout.Object.id (= CapturedRoom.Object.identifier)
        var id: UUID
        //가구 노드의 최종 transform - CameraPose와 같이 열 순서대로 16개의 값
        var transform: [Float]
    }
}

extension FurnitureArrangement {
    var isEmpty: Bool {
        placements.isEmpty
    }

    //transform이 nil이면 원래 위치로 되돌린 것이므로 저장된 값을 지움
    mutating func setTransform(_ transform: simd_float4x4?, for id: UUID) {
        if let index = placements.firstIndex(where: { $0.id == id }) {
            if let transform {
                placements[index].transform = transform.floats
            } else {
                placements.remove(at: index)
            }
        } else if let transform {
            placements.append(Placement(id: id, transform: transform.floats))
        }
    }
}

extension simd_float4x4 {
    //열 순서대로 펼친 16개의 값
    var floats: [Float] {
        [columns.0, columns.1, columns.2, columns.3].flatMap { [$0.x, $0.y, $0.z, $0.w] }
    }

    init?(floats: [Float]) {
        guard floats.count == 16 else { return nil }
        let column = { (index: Int) in SIMD4<Float>(floats[index * 4], floats[index * 4 + 1], floats[index * 4 + 2], floats[index * 4 + 3]) }
        self.init(column(0), column(1), column(2), column(3))
    }
}
