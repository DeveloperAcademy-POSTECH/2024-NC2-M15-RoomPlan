//
//  FurnitureCatalog.swift
//  MyRaum
//
//  Created by Yune Cho on 10/30/26.
//

import simd
import RoomPlan

//가구 목록에서 추가할 수 있는 가구의 종류와 기본 모양
enum FurnitureCatalog {
    //목록에 보여줄 순서 - 계단, 벽난로는 새로 놓을 일이 적으므로 제외
    static let categories: [FurnitureCategory] = [
        .sofa, .chair, .table, .bed, .storage, .television,
        .refrigerator, .stove, .oven, .dishwasher, .sink,
        .washerDryer, .toilet, .bathtub
    ]

    //종류별 기본 크기 (가로, 높이, 깊이) - 미터 단위
    static func defaultSize(of category: FurnitureCategory) -> SIMD3<Float> {
        switch category {
        case .sofa: [2.0, 0.85, 0.9]
        case .chair: [0.45, 0.85, 0.5]
        case .table: [1.4, 0.75, 0.8]
        case .bed: [1.5, 0.9, 2.05]
        case .storage: [0.8, 0.9, 0.45]
        case .television: [1.2, 0.75, 0.25]
        case .refrigerator: [0.7, 1.8, 0.7]
        case .stove: [0.6, 0.9, 0.6]
        case .oven: [0.6, 0.6, 0.55]
        case .dishwasher: [0.6, 0.85, 0.6]
        case .sink: [0.8, 0.9, 0.6]
        case .washerDryer: [0.6, 0.85, 0.6]
        case .toilet: [0.4, 0.75, 0.65]
        case .bathtub: [1.6, 0.55, 0.75]
        case .fireplace: [1.2, 1.0, 0.4]
        case .stairs: [1.0, 2.5, 3.0]
        }
    }

    //종류별 대표 형태 - 의자는 식탁 의자, 테이블은 사각 식탁, 소파는 일자형, 수납장은 문이 달린 장
    static func defaultAttributes(of category: FurnitureCategory) -> FurnitureAttributes {
        switch category {
        case .chair: FurnitureAttributes(chairType: .dining, chairLeg: .four, chairArm: .missing, chairBack: .existing)
        case .table: FurnitureAttributes(tableType: .dining, tableShape: .rectangular)
        case .sofa: FurnitureAttributes(sofaType: .rectangular)
        case .storage: FurnitureAttributes(storageType: .cabinet)
        default: FurnitureAttributes()
        }
    }
}
