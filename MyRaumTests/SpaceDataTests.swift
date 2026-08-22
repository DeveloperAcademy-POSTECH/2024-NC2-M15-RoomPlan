//
//  SpaceDataTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//SpaceData 모델의 기본 동작을 확인하는 테스트
struct SpaceDataTests {
    @Test("SpaceData 초기화 시 전달한 값이 그대로 보존된다")
    func initializerPreservesValues() {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_787_000_000)
        let space = SpaceData(
            id: id,
            createdAt: createdAt,
            comment: "작업실",
            latitude: 36.0190,
            longitude: 129.3435,
            storageKind: .usdz,
            modelFileName: "model.usdz",
            syncState: .pending
        )
        
        #expect(space.id == id)
        #expect(space.createdAt == createdAt)
        #expect(space.comment == "작업실")
        #expect(space.latitude == 36.0190)
        #expect(space.longitude == 129.3435)
        #expect(space.kind == .usdz)
        #expect(space.sync == .pending)
        #expect(space.modelFileName == "model.usdz")
        #expect(space.isPublic == false)
    }
    
    @Test("USDZ 카드의 미리보기 이미지는 썸네일을 사용한다")
    func usdzPreviewUsesThumbnail() {
        let space = SpaceData(
            createdAt: .now,
            comment: "작업실",
            latitude: 0,
            longitude: 0,
            storageKind: .usdz,
            legacyModelImage: Data([0xAA]),
            thumbnail: Data([0xBB]),
            syncState: .pending
        )
        
        #expect(space.previewImageData == Data([0xBB]))
    }
    
    @Test("레거시 카드의 미리보기 이미지는 누끼 이미지를 사용한다")
    func legacyPreviewUsesModelImage() {
        let space = SpaceData(
            createdAt: .now,
            comment: "작업실",
            latitude: 0,
            longitude: 0,
            storageKind: .legacyImage,
            legacyModelImage: Data([0xAA]),
            thumbnail: Data([0xBB]),
            syncState: .localOnly
        )
        
        #expect(space.previewImageData == Data([0xAA]))
    }
    
    @Test("원본 날짜 문자열이 있으면 그대로 표시한다")
    func displayDatePrefersLegacyText() {
        let space = SpaceData(
            createdAt: Date.distantPast,
            comment: "작업실",
            latitude: 0,
            longitude: 0,
            storageKind: .legacyImage,
            legacyDateText: "2024.06.19",
            syncState: .localOnly
        )
        
        #expect(space.displayDate == "2024.06.19")
    }
    
    @Test("원본 날짜 문자열이 없으면 createdAt을 포맷해서 표시한다")
    func displayDateFallsBackToCreatedAt() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 22
        let date = Calendar.current.date(from: components) ?? .now
        
        let space = SpaceData(
            createdAt: date,
            comment: "작업실",
            latitude: 0,
            longitude: 0,
            storageKind: .usdz,
            syncState: .pending
        )
        
        #expect(space.displayDate == "2026.08.22")
    }
}
