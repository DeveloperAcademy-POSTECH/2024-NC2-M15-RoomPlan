//
//  SpaceMigrationPlan.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import SwiftData

//V1 -> V2 마이그레이션 계획
enum SpaceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SpaceSchemaV1.self, SpaceSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    //model -> legacyModelImage, date -> legacyDateText 는 originalName으로 자동 이관된다
    //여기서는 자동으로 채울 수 없는 값(저장 방식 구분, createdAt)만 손으로 채운다
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SpaceSchemaV1.self,
        toVersion: SpaceSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let spaces = try context.fetch(FetchDescriptor<SpaceSchemaV2.SpaceData>())
            
            for space in spaces {
                space.storageKind = SpaceStorageKind.legacyImage.rawValue
                //레거시 카드는 서버에 올리지 않는다 (D-06)
                space.syncState = SpaceSyncState.localOnly.rawValue
                space.isPublic = false
                
                //"yyyy.MM.dd" 문자열을 Date로 파싱. 실패해도 원본 문자열은 legacyDateText에 남아 있다
                space.createdAt = SpaceMigrationPlan.parseLegacyDate(space.legacyDateText) ?? Date.distantPast
            }
            
            try context.save()
        }
    )
    
    //V1의 날짜 문자열을 Date로 바꾸는 함수
    static func parseLegacyDate(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.date(from: text)
    }
}
