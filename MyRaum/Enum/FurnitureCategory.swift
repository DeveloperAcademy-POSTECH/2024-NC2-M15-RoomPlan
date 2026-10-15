//
//  FurnitureCategory.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI
import RoomPlan

//RoomPlan이 인식하는 가구 종류
//rawValue는 저장용 키로 사용되므로 변경하면 안 됨
enum FurnitureCategory: String, CaseIterable, Codable {
    case storage
    case refrigerator
    case stove
    case bed
    case sink
    case washerDryer
    case toilet
    case bathtub
    case oven
    case dishwasher
    case table
    case sofa
    case chair
    case fireplace
    case television
    case stairs

    init?(_ category: CapturedRoom.Object.Category) {
        switch category {
        case .storage: self = .storage
        case .refrigerator: self = .refrigerator
        case .stove: self = .stove
        case .bed: self = .bed
        case .sink: self = .sink
        case .washerDryer: self = .washerDryer
        case .toilet: self = .toilet
        case .bathtub: self = .bathtub
        case .oven: self = .oven
        case .dishwasher: self = .dishwasher
        case .table: self = .table
        case .sofa: self = .sofa
        case .chair: self = .chair
        case .fireplace: self = .fireplace
        case .television: self = .television
        case .stairs: self = .stairs
        @unknown default: return nil
        }
    }

    var name: LocalizedStringKey {
        switch self {
        case .storage: "수납장"
        case .refrigerator: "냉장고"
        case .stove: "가스레인지"
        case .bed: "침대"
        case .sink: "싱크대"
        case .washerDryer: "세탁기"
        case .toilet: "변기"
        case .bathtub: "욕조"
        case .oven: "오븐"
        case .dishwasher: "식기세척기"
        case .table: "테이블"
        case .sofa: "소파"
        case .chair: "의자"
        case .fireplace: "벽난로"
        case .television: "TV"
        case .stairs: "계단"
        }
    }

    var symbol: String {
        switch self {
        case .storage: "cabinet"
        case .refrigerator: "refrigerator"
        case .stove: "stove"
        case .bed: "bed.double"
        case .sink: "sink"
        case .washerDryer: "washer"
        case .toilet: "toilet"
        case .bathtub: "bathtub"
        case .oven: "oven"
        case .dishwasher: "dishwasher"
        case .table: "table.furniture"
        case .sofa: "sofa"
        case .chair: "chair"
        case .fireplace: "fireplace"
        case .television: "tv"
        case .stairs: "stairs"
        }
    }
}

struct FurnitureCount: Identifiable {
    let category: FurnitureCategory
    let count: Int

    var id: FurnitureCategory { category }

    //가구 목록을 종류별 개수로 묶어서 많은 순서대로 정렬
    static func summarize(_ furniture: [FurnitureCategory]) -> [FurnitureCount] {
        Dictionary(grouping: furniture, by: { $0 })
            .map { FurnitureCount(category: $0.key, count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.category.rawValue < $1.category.rawValue : $0.count > $1.count }
    }
}
