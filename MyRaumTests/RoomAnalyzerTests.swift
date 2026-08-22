//
//  RoomAnalyzerTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//가구 조합으로 방 종류를 추론하는 규칙을 확인하는 테스트
struct RoomAnalyzerTests {
    @Test("침대가 있으면 침실로 본다")
    func bedMeansBedroom() {
        let furniture = [makeFurniture(category: "bed"), makeFurniture(category: "storage")]
        
        #expect(RoomAnalyzer.roomType(from: furniture) == .bedroom)
    }
    
    @Test("주방 가구가 있으면 주방으로 본다", arguments: ["refrigerator", "stove", "dishwasher", "sink"])
    func kitchenCategories(category: String) {
        #expect(RoomAnalyzer.roomType(from: [makeFurniture(category: category)]) == .kitchen)
    }
    
    @Test("소파나 TV가 있으면 거실로 본다", arguments: ["sofa", "television"])
    func livingRoomCategories(category: String) {
        #expect(RoomAnalyzer.roomType(from: [makeFurniture(category: category)]) == .livingRoom)
    }
    
    @Test("변기나 욕조가 있으면 욕실로 본다", arguments: ["toilet", "bathtub"])
    func bathroomCategories(category: String) {
        #expect(RoomAnalyzer.roomType(from: [makeFurniture(category: category)]) == .bathroom)
    }
    
    @Test("침대가 있으면 다른 가구가 섞여 있어도 침실이 우선한다")
    func bedTakesPriority() {
        let furniture = [
            makeFurniture(category: "sofa"),
            makeFurniture(category: "television"),
            makeFurniture(category: "bed")
        ]
        
        #expect(RoomAnalyzer.roomType(from: furniture) == .bedroom)
    }
    
    @Test("판단 근거가 없으면 unknown")
    func unknownWithoutSignals() {
        #expect(RoomAnalyzer.roomType(from: []) == .unknown)
        #expect(RoomAnalyzer.roomType(from: [makeFurniture(category: "chair")]) == .unknown)
    }
    
    @Test("신뢰도가 낮은 항목 수를 센다")
    func countsLowConfidenceItems() {
        let metrics = RoomMetrics(
            floorAreaSqM: 12.0,
            roomType: .bedroom,
            furniture: [
                makeFurniture(category: "bed", confidence: "high"),
                makeFurniture(category: "chair", confidence: "low"),
                makeFurniture(category: "table", confidence: "low")
            ]
        )
        
        #expect(metrics.lowConfidenceCount == 2)
    }
}

//가구 목록의 JSON 직렬화를 확인하는 테스트
struct CapturedFurnitureTests {
    @Test("가구 목록이 JSON으로 저장되고 그대로 복원된다")
    func encodesAndDecodes() throws {
        let original = [
            makeFurniture(category: "bed"),
            makeFurniture(category: "storage", confidence: "low")
        ]
        
        let json = try #require(original.encodedJSON())
        let restored = [CapturedFurniture].decoded(from: json)
        
        #expect(restored == original)
        #expect(restored[1].isLowConfidence == true)
    }
    
    @Test("JSON이 없거나 깨져 있으면 빈 목록을 리턴한다")
    func decodesBrokenJSONSafely() {
        #expect([CapturedFurniture].decoded(from: nil).isEmpty)
        #expect([CapturedFurniture].decoded(from: "not json").isEmpty)
    }
}
