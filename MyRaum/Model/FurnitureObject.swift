//
//  FurnitureObject.swift
//  MyRaum
//
//  Created by Yune Cho on 11/15/26.
//

import SwiftUI
import simd

//오브젝트 탭과 가구 추가 시트에 보여주는 가구 하나
//가구 목록의 기본 가구와 (이후 버전의) Object Capture로 스캔한 내 가구를 같은 화면에서 같은 방식으로 다루기 위한 타입
//화면은 source로 가구를 구분하고, 공간에 추가할 때도 source와 size만 넘김
struct FurnitureObject: Identifiable {
    let source: FurnitureSource
    //기본 가구는 번역할 키, 사용자가 이름을 정한 가구는 "\(name)"처럼 문자열을 그대로 보여주는 키를 사용
    let name: LocalizedStringKey
    //가구 개수, 겹침 판단에 사용하는 종류 - 스캔한 가구는 사용자가 고른 종류
    let category: FurnitureCategory?
    //미리보기 이미지를 만들기 전이나 만들지 못했을 때 보여줄 SF Symbol
    let symbol: String
    //공간에 추가할 때의 기본 크기 (가로, 높이, 깊이) - 미터 단위
    let size: SIMD3<Float>

    var id: FurnitureSource { source }
}

extension FurnitureObject {
    init(_ item: FurnitureCatalogItem) {
        self.init(source: .catalog(item.id), name: item.name, category: item.category, symbol: item.symbol, size: item.size)
    }
}

//오브젝트 탭과 가구 추가 시트가 함께 사용하는 가구 목록
//지금은 기본 가구만 있음 - Object Capture로 스캔한 가구를 추가하면 "내 가구" 섹션을 맨 앞에 붙이고
//object(for:)에서 FurnitureSource의 새 case를 찾도록 확장
enum FurnitureLibrary {
    struct Section: Identifiable {
        let id: String
        let title: LocalizedStringKey
        let objects: [FurnitureObject]
    }

    static let catalogSections: [Section] = FurnitureCatalog.sections.map { section in
        Section(id: "catalog.\(section.id)", title: section.title, objects: section.items.map(FurnitureObject.init))
    }

    static var sections: [Section] {
        catalogSections
    }

    static func object(for source: FurnitureSource) -> FurnitureObject? {
        switch source {
        case .catalog(let id): FurnitureCatalog.item(id).map(FurnitureObject.init)
        }
    }
}
