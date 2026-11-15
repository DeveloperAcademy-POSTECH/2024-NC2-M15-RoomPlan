//
//  FurnitureCatalog.swift
//  MyRaum
//
//  Created by Yune Cho on 10/30/26.
//

import SwiftUI
import simd
import RoomPlan

//가구 목록에 있는 기본 가구 하나 - 종류, 형태 정보, 기본 크기로 FurnitureModelBuilder가 모양을 만듦
//id는 FurnitureSource.catalog로 저장되므로 변경하면 안 됨
//각 종류의 대표 가구는 id가 FurnitureCategory.rawValue와 같음 (1.1.1까지 종류만 저장한 가구를 대표 가구로 읽음)
struct FurnitureCatalogItem: Identifiable {
    typealias ID = String

    let id: ID
    let category: FurnitureCategory
    let name: LocalizedStringKey
    let symbol: String
    //기본 크기 (가로, 높이, 깊이) - 미터 단위
    let size: SIMD3<Float>
    let attributes: FurnitureAttributes

    init(_ id: ID, _ category: FurnitureCategory, name: LocalizedStringKey, symbol: String? = nil, size: SIMD3<Float>, attributes: FurnitureAttributes = FurnitureAttributes()) {
        self.id = id
        self.category = category
        self.name = name
        self.symbol = symbol ?? category.symbol
        self.size = size
        self.attributes = attributes
    }
}

//가구 목록에서 추가할 수 있는 기본 가구들
//RoomPlan이 인식하는 형태 정보(의자 다리, 소파 모양, 테이블 모양 등)를 조합해서 같은 종류의 여러 가구를 만듦
//새 가구를 추가할 때는 id를 "종류.이름" 형식으로 겹치지 않게 정하고, 한 번 정한 id는 바꾸지 않음
enum FurnitureCatalog {
    struct Section: Identifiable {
        let id: String
        let title: LocalizedStringKey
        let items: [FurnitureCatalogItem]
    }

    static let sections: [Section] = [
        Section(id: "chair", title: "의자", items: [
            FurnitureCatalogItem("chair", .chair, name: "식탁 의자", size: [0.45, 0.85, 0.5],
                                 attributes: FurnitureAttributes(chairType: .dining, chairLeg: .four, chairArm: .missing, chairBack: .existing)),
            FurnitureCatalogItem("chair.armchair", .chair, name: "팔걸이 의자", size: [0.58, 0.85, 0.56],
                                 attributes: FurnitureAttributes(chairType: .dining, chairLeg: .four, chairArm: .existing, chairBack: .existing)),
            FurnitureCatalogItem("chair.swivel", .chair, name: "사무용 의자", size: [0.62, 1.0, 0.62],
                                 attributes: FurnitureAttributes(chairType: .swivel, chairLeg: .star, chairArm: .existing, chairBack: .existing)),
            FurnitureCatalogItem("chair.stool", .chair, name: "스툴", size: [0.4, 0.45, 0.4],
                                 attributes: FurnitureAttributes(chairType: .stool, chairLeg: .four, chairArm: .missing, chairBack: .missing)),
            FurnitureCatalogItem("chair.barStool", .chair, name: "바 스툴", size: [0.4, 0.75, 0.4],
                                 attributes: FurnitureAttributes(chairType: .stool, chairLeg: .star, chairArm: .missing, chairBack: .missing))
        ]),
        Section(id: "sofa", title: "소파", items: [
            FurnitureCatalogItem("sofa", .sofa, name: "일자형 소파", size: [2.0, 0.85, 0.9],
                                 attributes: FurnitureAttributes(sofaType: .rectangular)),
            FurnitureCatalogItem("sofa.singleSeat", .sofa, name: "1인 소파", size: [0.95, 0.85, 0.9],
                                 attributes: FurnitureAttributes(sofaType: .singleSeat)),
            FurnitureCatalogItem("sofa.lShaped", .sofa, name: "L자형 소파", size: [2.6, 0.85, 1.7],
                                 attributes: FurnitureAttributes(sofaType: .lShaped)),
            FurnitureCatalogItem("sofa.chaise", .sofa, name: "카우치 소파", size: [2.4, 0.85, 1.5],
                                 attributes: FurnitureAttributes(sofaType: .lShapedExtension))
        ]),
        Section(id: "table", title: "테이블", items: [
            FurnitureCatalogItem("table", .table, name: "식탁", size: [1.4, 0.75, 0.8],
                                 attributes: FurnitureAttributes(tableType: .dining, tableShape: .rectangular)),
            FurnitureCatalogItem("table.round", .table, name: "원형 식탁", size: [1.0, 0.75, 1.0],
                                 attributes: FurnitureAttributes(tableType: .dining, tableShape: .circularElliptic)),
            FurnitureCatalogItem("table.desk", .table, name: "책상", size: [1.2, 0.73, 0.6],
                                 attributes: FurnitureAttributes(tableType: .dining, tableShape: .rectangular)),
            FurnitureCatalogItem("table.lShapedDesk", .table, name: "L자형 책상", size: [1.6, 0.73, 1.4],
                                 attributes: FurnitureAttributes(tableType: .dining, tableShape: .lShaped)),
            FurnitureCatalogItem("table.coffee", .table, name: "커피 테이블", size: [1.0, 0.4, 0.55],
                                 attributes: FurnitureAttributes(tableType: .coffee, tableShape: .rectangular)),
            FurnitureCatalogItem("table.roundCoffee", .table, name: "원형 커피 테이블", size: [0.7, 0.4, 0.7],
                                 attributes: FurnitureAttributes(tableType: .coffee, tableShape: .circularElliptic))
        ]),
        Section(id: "bed", title: "침대", items: [
            FurnitureCatalogItem("bed.single", .bed, name: "싱글 침대", size: [1.0, 0.9, 2.0]),
            FurnitureCatalogItem("bed", .bed, name: "더블 침대", size: [1.5, 0.9, 2.05]),
            FurnitureCatalogItem("bed.king", .bed, name: "킹 침대", size: [1.8, 0.95, 2.1])
        ]),
        Section(id: "storage", title: "수납", items: [
            FurnitureCatalogItem("storage", .storage, name: "수납장", size: [0.8, 0.9, 0.45],
                                 attributes: FurnitureAttributes(storageType: .cabinet)),
            FurnitureCatalogItem("storage.wardrobe", .storage, name: "옷장", size: [1.2, 2.0, 0.6],
                                 attributes: FurnitureAttributes(storageType: .cabinet)),
            FurnitureCatalogItem("storage.tvStand", .storage, name: "TV 거실장", size: [1.6, 0.45, 0.4],
                                 attributes: FurnitureAttributes(storageType: .cabinet)),
            FurnitureCatalogItem("storage.bookshelf", .storage, name: "책장", symbol: "books.vertical", size: [0.8, 1.8, 0.3],
                                 attributes: FurnitureAttributes(storageType: .shelf)),
            FurnitureCatalogItem("storage.shelf", .storage, name: "선반", symbol: "books.vertical", size: [1.2, 0.8, 0.35],
                                 attributes: FurnitureAttributes(storageType: .shelf))
        ]),
        Section(id: "living", title: "거실", items: [
            FurnitureCatalogItem("television", .television, name: "TV", size: [1.2, 0.75, 0.25]),
            FurnitureCatalogItem("television.large", .television, name: "대형 TV", size: [1.65, 1.05, 0.3]),
            FurnitureCatalogItem("fireplace", .fireplace, name: "벽난로", size: [1.2, 1.0, 0.4])
        ]),
        Section(id: "kitchen", title: "주방", items: [
            FurnitureCatalogItem("refrigerator", .refrigerator, name: "냉장고", size: [0.7, 1.8, 0.7]),
            FurnitureCatalogItem("stove", .stove, name: "가스레인지", size: [0.6, 0.9, 0.6]),
            FurnitureCatalogItem("oven", .oven, name: "오븐", size: [0.6, 0.6, 0.55]),
            FurnitureCatalogItem("dishwasher", .dishwasher, name: "식기세척기", size: [0.6, 0.85, 0.6]),
            FurnitureCatalogItem("sink", .sink, name: "싱크대", size: [0.8, 0.9, 0.6])
        ]),
        Section(id: "bathroom", title: "욕실·세탁", items: [
            FurnitureCatalogItem("toilet", .toilet, name: "변기", size: [0.4, 0.75, 0.65]),
            FurnitureCatalogItem("bathtub", .bathtub, name: "욕조", size: [1.6, 0.55, 0.75]),
            FurnitureCatalogItem("washerDryer", .washerDryer, name: "세탁기", size: [0.6, 0.85, 0.6])
        ]),
        Section(id: "structure", title: "구조물", items: [
            FurnitureCatalogItem("stairs", .stairs, name: "계단", size: [1.0, 2.5, 3.0])
        ])
    ]

    static let items: [FurnitureCatalogItem] = sections.flatMap(\.items)

    private static let itemsByID: [FurnitureCatalogItem.ID: FurnitureCatalogItem] = Dictionary(
        items.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func item(_ id: FurnitureCatalogItem.ID) -> FurnitureCatalogItem? {
        itemsByID[id]
    }

    //종류의 대표 가구 - 종류만 알고 있는 가구(이전 버전 데이터, 모르는 가구)를 보여줄 때 사용
    static func baseItem(of category: FurnitureCategory) -> FurnitureCatalogItem {
        itemsByID[category.rawValue] ?? FurnitureCatalogItem(category.rawValue, category, name: category.name, size: [1, 1, 1])
    }
}
