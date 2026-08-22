//
//  LocalSpaceRepository.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import SwiftData

//SwiftData를 사용해 공간 데이터를 로컬에 저장하는 구현체
@MainActor
final class LocalSpaceRepository: SpaceRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    //SwiftData에 공간 정보를 저장하는 함수
    @discardableResult
    func save(_ space: SpaceData) -> Bool {
        do {
            modelContext.insert(space)
            try modelContext.save()
        } catch {
            print("Failed to save data")
            return false
        }
        return true
    }
    
    //SwiftData에서 데이터를 삭제하는 함수
    func delete(_ space: SpaceData) {
        do {
            modelContext.delete(space)
            try modelContext.save()
        } catch {
            print("Failed to save data")
        }
    }
    
    //저장된 모든 공간을 최신순으로 가져오는 함수
    func fetchAll() -> [SpaceData] {
        do {
            return try modelContext.fetch(FetchDescriptor<SpaceData>())
        } catch {
            print("Failed to fetch data")
            return []
        }
    }
}
