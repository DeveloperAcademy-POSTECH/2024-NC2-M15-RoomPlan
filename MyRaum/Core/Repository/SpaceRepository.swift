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
    //저장 방식별 개수. 레거시 카드 존재 여부 판단에 사용한다
    func count(of kind: SpaceStorageKind) -> Int
    //동기화가 필요한 공간 목록
    func fetchPendingUpload() -> [SpaceData]
    //이미 저장된 객체의 변경 사항만 반영한다
    func saveChanges()
}
