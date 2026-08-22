//
//  RoomAnalyzer.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import simd
import RoomPlan

//스캔 결과에서 가구·면적·방 종류를 뽑아내는 역할
enum RoomAnalyzer {
    //CapturedRoom에서 저장할 파생 데이터를 모두 뽑아내는 함수
    static func metrics(from room: CapturedRoom) -> RoomMetrics {
        let furniture = furniture(from: room)
        
        return RoomMetrics(
            floorAreaSqM: floorArea(from: room),
            roomType: roomType(from: furniture),
            furniture: furniture
        )
    }
    
    //인식된 오브젝트를 저장 가능한 형태로 변환하는 함수
    static func furniture(from room: CapturedRoom) -> [CapturedFurniture] {
        room.objects.map { object in
            CapturedFurniture(
                id: object.identifier,
                category: String(describing: object.category),
                width: Double(object.dimensions.x),
                height: Double(object.dimensions.y),
                length: Double(object.dimensions.z),
                confidence: String(describing: object.confidence),
                transform: object.transform.columnMajorValues
            )
        }
    }
    
    //바닥 면적을 산출하는 함수. 바닥이 인식되지 않았으면 nil
    static func floorArea(from room: CapturedRoom) -> Double? {
        let floors = room.floors
        guard floors.isEmpty == false else { return nil }
        
        let area = floors.reduce(0.0) { total, floor in
            total + Double(floor.dimensions.x) * Double(floor.dimensions.y)
        }
        
        return area > 0 ? area : nil
    }
    
    //가구 카테고리 조합으로 방 종류를 추론하는 함수
    static func roomType(from furniture: [CapturedFurniture]) -> RoomTypeGuess {
        let categories = Set(furniture.map(\.category))
        
        if categories.contains("bed") {
            return .bedroom
        }
        if categories.isDisjoint(with: ["refrigerator", "stove", "dishwasher", "sink"]) == false {
            return .kitchen
        }
        if categories.isDisjoint(with: ["sofa", "television"]) == false {
            return .livingRoom
        }
        if categories.isDisjoint(with: ["toilet", "bathtub"]) == false {
            return .bathroom
        }
        
        return .unknown
    }
}

private extension simd_float4x4 {
    //4x4 행렬을 열 우선 순서로 펼치는 함수
    var columnMajorValues: [Double] {
        [columns.0, columns.1, columns.2, columns.3].flatMap { column in
            [Double(column.x), Double(column.y), Double(column.z), Double(column.w)]
        }
    }
}
