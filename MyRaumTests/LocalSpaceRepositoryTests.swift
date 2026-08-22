//
//  LocalSpaceRepositoryTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import SwiftData
@testable import MyRaum

//SwiftData 저장소의 저장·삭제·조회 동작을 확인하는 테스트
//ModelConfiguration에 Schema를 명시하지 않으면 SwiftData가 SIGTRAP으로 죽으므로 반드시 함께 넘긴다
@Suite(.serialized)
@MainActor
struct LocalSpaceRepositoryTests {
    private let fileStore = FakeModelFileStore()
    
    //테스트마다 격리된 인메모리 저장소를 만드는 함수
    private func makeRepository() throws -> LocalSpaceRepository {
        let schema = Schema(versionedSchema: SpaceSchemaV2.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        return LocalSpaceRepository(modelContext: ModelContext(container), modelFileStore: fileStore)
    }
    
    @Test("저장한 공간이 조회 결과에 포함된다")
    func saveThenFetch() throws {
        let repository = try makeRepository()
        let space = makeSpaceData(comment: "작업실")
        
        #expect(repository.save(space) == true)
        
        let fetched = repository.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched.first?.comment == "작업실")
    }
    
    @Test("삭제한 공간은 조회 결과에서 사라진다")
    func deleteRemovesSpace() throws {
        let repository = try makeRepository()
        let first = makeSpaceData(comment: "작업실")
        let second = makeSpaceData(comment: "침실")
        repository.save(first)
        repository.save(second)
        #expect(repository.fetchAll().count == 2)
        
        repository.delete(first)
        
        let remaining = repository.fetchAll()
        #expect(remaining.count == 1)
        #expect(remaining.first?.comment == "침실")
    }
    
    @Test("여러 공간을 저장해도 모두 보존된다")
    func saveMultipleSpaces() throws {
        let repository = try makeRepository()
        
        for index in 0..<5 {
            repository.save(makeSpaceData(comment: "공간 \(index)"))
        }
        
        #expect(repository.fetchAll().count == 5)
    }
    
    @Test("저장한 공간의 위경도가 그대로 보존된다")
    func saveKeepsCoordinate() throws {
        let repository = try makeRepository()
        repository.save(makeSpaceData())
        
        let fetched = try #require(repository.fetchAll().first)
        #expect(fetched.latitude == 36.0190)
        #expect(fetched.longitude == 129.3435)
    }
    
    @Test("USDZ 카드를 삭제하면 모델 파일도 함께 지운다")
    func deleteAlsoRemovesModelFile() throws {
        let repository = try makeRepository()
        let space = makeSpaceData(storageKind: .usdz, modelFileName: "room.usdz")
        repository.save(space)
        
        repository.delete(space)
        
        #expect(fileStore.deletedFileNames == ["room.usdz"])
    }
    
    @Test("조회 결과는 최신순으로 정렬된다")
    func fetchAllSortsByCreatedAtDescending() throws {
        let repository = try makeRepository()
        let older = makeSpaceData(comment: "예전", createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        let newer = makeSpaceData(comment: "최근", createdAt: Date(timeIntervalSince1970: 1_800_000_000))
        repository.save(older)
        repository.save(newer)
        
        #expect(repository.fetchAll().map(\.comment) == ["최근", "예전"])
    }
}
