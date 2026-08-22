//
//  SpaceMigrationTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import SwiftData
@testable import MyRaum

//V1 -> V2 마이그레이션에서 기존 사용자 데이터가 손실되지 않는지 확인하는 테스트 (FR-02)
@Suite(.serialized)
@MainActor
struct SpaceMigrationTests {
    //임시 파일에 V1 스토어를 만들고 V2로 다시 열어 보는 함수
    private func migrate(
        seed: (ModelContext) throws -> Void
    ) throws -> [SpaceData] {
        let storeURL = FileManager.default.temporaryDirectory
            .appending(path: "migration-\(UUID().uuidString).store")
        
        //V1 스키마로 스토어를 만들고 기존 사용자 데이터를 흉내낸다
        do {
            let schemaV1 = Schema(versionedSchema: SpaceSchemaV1.self)
            let container = try ModelContainer(
                for: schemaV1,
                configurations: ModelConfiguration(schema: schemaV1, url: storeURL)
            )
            let context = ModelContext(container)
            try seed(context)
            try context.save()
        }
        
        //같은 스토어를 V2 + 마이그레이션 계획으로 다시 연다
        let schemaV2 = Schema(versionedSchema: SpaceSchemaV2.self)
        let container = try ModelContainer(
            for: schemaV2,
            migrationPlan: SpaceMigrationPlan.self,
            configurations: ModelConfiguration(schema: schemaV2, url: storeURL)
        )
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<SpaceData>())
    }
    
    private func makeV1Space(date: String, comment: String) -> SpaceSchemaV1.SpaceData {
        SpaceSchemaV1.SpaceData(
            id: UUID(),
            date: date,
            comment: comment,
            model: Data([0xAA, 0xBB]),
            background: Data([0xCC, 0xDD]),
            latitude: 36.0190,
            longitude: 129.3435
        )
    }
    
    @Test("V1 카드가 손실 없이 V2로 옮겨진다")
    func migratesWithoutLoss() throws {
        let spaces = try migrate { context in
            context.insert(makeV1Space(date: "2024.06.19", comment: "작업실"))
        }
        
        let space = try #require(spaces.first)
        #expect(spaces.count == 1)
        #expect(space.comment == "작업실")
        #expect(space.latitude == 36.0190)
        #expect(space.longitude == 129.3435)
        //누끼 이미지와 배경이 그대로 이관되어야 한다
        #expect(space.legacyModelImage == Data([0xAA, 0xBB]))
        #expect(space.background == Data([0xCC, 0xDD]))
    }
    
    @Test("마이그레이션된 카드는 legacyImage · localOnly 로 표시된다")
    func migratedCardIsLegacyAndLocalOnly() throws {
        let spaces = try migrate { context in
            context.insert(makeV1Space(date: "2024.06.19", comment: "작업실"))
        }
        
        let space = try #require(spaces.first)
        #expect(space.kind == .legacyImage)
        //레거시 카드는 서버에 올리지 않는다 (D-06)
        #expect(space.sync == .localOnly)
        #expect(space.isPublic == false)
        #expect(space.modelFileName == nil)
    }
    
    @Test("date 문자열이 createdAt으로 파싱된다")
    func parsesDateStringIntoCreatedAt() throws {
        let spaces = try migrate { context in
            context.insert(makeV1Space(date: "2024.06.19", comment: "작업실"))
        }
        
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 19
        let expected = Calendar.current.date(from: components)
        
        let space = try #require(spaces.first)
        #expect(space.createdAt == expected)
        //원본 문자열도 함께 보존되어야 한다
        #expect(space.legacyDateText == "2024.06.19")
        #expect(space.displayDate == "2024.06.19")
    }
    
    @Test("파싱할 수 없는 날짜여도 원본 문자열이 보존되고 표시가 깨지지 않는다")
    func keepsUnparsableDateText() throws {
        let spaces = try migrate { context in
            context.insert(makeV1Space(date: "언젠가", comment: "작업실"))
        }
        
        let space = try #require(spaces.first)
        #expect(space.createdAt == Date.distantPast)
        #expect(space.legacyDateText == "언젠가")
        #expect(space.displayDate == "언젠가")
    }
    
    @Test("여러 건의 V1 카드가 모두 옮겨진다")
    func migratesMultipleCards() throws {
        let spaces = try migrate { context in
            context.insert(makeV1Space(date: "2024.06.19", comment: "작업실"))
            context.insert(makeV1Space(date: "2024.07.01", comment: "침실"))
            context.insert(makeV1Space(date: "2025.01.15", comment: "거실"))
        }
        
        #expect(spaces.count == 3)
        #expect(Set(spaces.map(\.comment)) == ["작업실", "침실", "거실"])
        #expect(spaces.allSatisfy { $0.kind == .legacyImage })
    }
}
