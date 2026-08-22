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
        let space = SpaceData(
            id: id,
            date: "2026.08.22",
            comment: "작업실",
            model: Data([0x01]),
            background: Data([0x02]),
            latitude: 36.0190,
            longitude: 129.3435
        )
        
        #expect(space.id == id)
        #expect(space.date == "2026.08.22")
        #expect(space.comment == "작업실")
        #expect(space.model == Data([0x01]))
        #expect(space.background == Data([0x02]))
        #expect(space.latitude == 36.0190)
        #expect(space.longitude == 129.3435)
    }
}
