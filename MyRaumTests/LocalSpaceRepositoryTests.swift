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
//같은 프로세스에서 같은 모델의 ModelContainer를 여러 번 만들면 SwiftData가 죽으므로
//컨테이너는 하나만 만들어 재사용하고, 테스트는 순차로 실행한다
@Suite(.serialized)
@MainActor
struct LocalSpaceRepositoryTests {
    private static let sharedContainer: ModelContainer? = try? ModelContainer(
        for: SpaceData.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    //이전 테스트가 남긴 데이터를 지운 새 컨텍스트로 저장소를 만드는 함수
    private func makeRepository() throws -> LocalSpaceRepository {
        let container = try #require(Self.sharedContainer)
        let context = ModelContext(container)
        try context.delete(model: SpaceData.self)
        try context.save()
        return LocalSpaceRepository(modelContext: context)
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
}
