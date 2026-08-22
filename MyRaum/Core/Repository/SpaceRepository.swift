//
//  SpaceRepository.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//공간 데이터의 저장·삭제·조회를 담당하는 역할
@MainActor
protocol SpaceRepository {
    //저장에 성공하면 true를 리턴
    @discardableResult
    func save(_ space: SpaceData) -> Bool
    func delete(_ space: SpaceData)
    func fetchAll() -> [SpaceData]
}
