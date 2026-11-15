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
//- version 1: placements
//- version 2: additions, removedIDs (가구 목록에서 추가한 가구, 지운 스캔 가구)
//  1.1.2부터 additions의 source에 item이 추가되었지만 이전 버전도 읽을 수 있는 형식이므로 version은 그대로 2
struct FurnitureArrangement: Codable, Equatable {
    static let currentVersion = 2

    var version: Int = FurnitureArrangement.currentVersion
    //RoomPlan이 인식한 가구 중 원래 위치에서 옮기거나 돌린 가구
    var placements: [Placement] = []
    //가구 목록에서 추가한 가구 - version 1 데이터에는 없음
    var additions: [Addition]?
    //지운 스캔 가구의 ID (RoomLayout.Object.id) - version 1 데이터에는 없음
    var removedIDs: [UUID]?

    struct Placement: Codable, Equatable {
        //RoomLayout.Object.id (= CapturedRoom.Object.identifier)
        var id: UUID
        //가구 노드의 최종 transform - CameraPose와 같이 열 순서대로 16개의 값
        var transform: [Float]
    }

    //사용자가 추가한 가구
    struct Addition: Codable, Equatable {
        //추가할 때 새로 만든 ID
        var id: UUID
        var source: FurnitureSource
        //가구 노드의 로컬 좌표 기준 크기 (가로, 높이, 깊이) - 미터 단위의 3개의 값
        var size: [Float]
        //가구 노드의 transform - 열 순서대로 16개의 값
        var transform: [Float]
    }
}

//추가한 가구의 모양을 어디서 가져오는지
//저장 형식: {"kind": "catalog", "item": "chair.stool", "category": "chair"}
//- item: FurnitureCatalogItem.id (1.1.2부터) - 1.1.1까지는 category만 저장했으므로 item이 없으면 그 종류의 대표 가구로 읽음
//- category: 이전 버전 앱이 item을 모르더라도 같은 종류의 대표 가구로 보여줄 수 있도록 항상 함께 저장
//Object Capture로 스캔한 가구는 kind "captured"와 스캔 가구의 ID로 추가할 예정
//- 이 버전부터는 모르는 kind를 category의 대표 가구로 읽고, category도 없으면 그 가구만 건너뜀
//- 그러므로 스캔한 가구에도 사용자가 고른 category를 함께 저장해야 이전 버전에서도 비슷한 모양으로 보임
enum FurnitureSource: Hashable {
    //가구 목록의 기본 가구
    case catalog(FurnitureCatalogItem.ID)
}

extension FurnitureSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case item
        case category
    }

    private enum Kind: String, Codable {
        case catalog
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = Kind(rawValue: try container.decode(String.self, forKey: .kind))
        //이후 버전에서 추가한 종류는 모를 수 있으므로 읽지 못해도 실패하지 않음
        let category = (try? container.decodeIfPresent(FurnitureCategory.self, forKey: .category)) ?? nil

        switch kind {
        case .catalog:
            if let id = try container.decodeIfPresent(String.self, forKey: .item), FurnitureCatalog.item(id) != nil {
                self = .catalog(id)
                return
            }
        case nil:
            break
        }

        //모르는 가구는 같은 종류의 대표 가구로 보여줌
        guard let category else {
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown furniture source")
        }
        self = .catalog(FurnitureCatalog.baseItem(of: category).id)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .catalog(let id):
            try container.encode(Kind.catalog, forKey: .kind)
            try container.encode(id, forKey: .item)
        }
        try container.encodeIfPresent(category, forKey: .category)
    }

    //가구 목록과 개수에 표시할 종류
    var category: FurnitureCategory? {
        switch self {
        case .catalog(let id): FurnitureCatalog.item(id)?.category
        }
    }
}

//읽을 수 없는 항목이 있어도 배치 전체를 잃지 않도록 추가한 가구는 하나씩 읽음
//(SpaceRecord.arrangement는 읽기에 실패하면 nil이 되어 모든 배치가 사라짐)
extension FurnitureArrangement {
    private enum CodingKeys: String, CodingKey {
        case version
        case placements
        case additions
        case removedIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        placements = try container.decodeIfPresent([Placement].self, forKey: .placements) ?? []
        additions = try container.decodeIfPresent([Lossy<Addition>].self, forKey: .additions)?.compactMap(\.value)
        removedIDs = try container.decodeIfPresent([UUID].self, forKey: .removedIDs)
    }
}

//읽지 못한 값은 nil로 두는 래퍼
private struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

extension FurnitureArrangement {
    var isEmpty: Bool {
        placements.isEmpty && (additions ?? []).isEmpty && (removedIDs ?? []).isEmpty
    }

    func isAdded(_ id: UUID) -> Bool {
        additions?.contains { $0.id == id } == true
    }

    func isRemoved(_ id: UUID) -> Bool {
        removedIDs?.contains(id) == true
    }

    //추가한 가구는 항목의 transform을 바꾸고, 스캔 가구는 placements에 저장
    //스캔 가구의 transform이 nil이면 원래 위치로 되돌린 것이므로 저장된 값을 지움
    mutating func setTransform(_ transform: simd_float4x4?, for id: UUID) {
        if let index = additions?.firstIndex(where: { $0.id == id }) {
            if let transform {
                additions?[index].transform = transform.floats
            }
            return
        }
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

    mutating func add(_ addition: Addition) {
        additions = (additions ?? []) + [addition]
        version = Self.currentVersion
    }

    //추가한 가구는 목록에서 빼고, 스캔 가구는 지운 목록에 넣음
    mutating func remove(_ id: UUID) {
        if let index = additions?.firstIndex(where: { $0.id == id }) {
            additions?.remove(at: index)
            if additions?.isEmpty == true {
                additions = nil
            }
            return
        }
        placements.removeAll { $0.id == id }
        if !isRemoved(id) {
            removedIDs = (removedIDs ?? []) + [id]
        }
        version = Self.currentVersion
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
