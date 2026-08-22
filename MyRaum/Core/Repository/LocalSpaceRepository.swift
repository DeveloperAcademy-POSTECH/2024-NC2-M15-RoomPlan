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
    private let modelFileStore: any ModelFileStoring
    
    init(modelContext: ModelContext, modelFileStore: any ModelFileStoring) {
        self.modelContext = modelContext
        self.modelFileStore = modelFileStore
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
    //USDZ로 저장된 공간은 모델 파일도 함께 지운다
    func delete(_ space: SpaceData) {
        if let modelFileName = space.modelFileName {
            modelFileStore.delete(fileName: modelFileName)
        }
        
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
            let descriptor = FetchDescriptor<SpaceData>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch data")
            return []
        }
    }
    
    //저장 방식별 개수를 세는 함수
    func count(of kind: SpaceStorageKind) -> Int {
        let rawValue = kind.rawValue
        let descriptor = FetchDescriptor<SpaceData>(
            predicate: #Predicate { $0.storageKind == rawValue }
        )
        
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Failed to count data")
            return 0
        }
    }
    
    //업로드가 필요한 공간을 가져오는 함수
    //레거시 카드는 업로드 대상이 아니다 (D-06, 6B.10)
    func fetchPendingUpload() -> [SpaceData] {
        let usdzKind = SpaceStorageKind.usdz.rawValue
        let pending = SpaceSyncState.pending.rawValue
        let failed = SpaceSyncState.failed.rawValue
        
        let descriptor = FetchDescriptor<SpaceData>(
            predicate: #Predicate {
                $0.storageKind == usdzKind && ($0.syncState == pending || $0.syncState == failed)
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch pending uploads")
            return []
        }
    }
    
    //이미 저장된 객체의 변경 사항만 반영하는 함수
    func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save changes")
        }
    }
}
