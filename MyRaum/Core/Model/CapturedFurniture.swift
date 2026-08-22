//
//  CapturedFurniture.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//RoomPlan이 인식한 가구 하나의 정보
struct CapturedFurniture: Codable, Identifiable, Hashable {
    let id: UUID
    //RoomPlan의 CapturedRoom.Object.Category rawValue
    let category: String
    //가로·세로·높이 (m)
    let width: Double
    let height: Double
    let length: Double
    //low / medium / high
    let confidence: String
    //4x4 변환 행렬을 열 우선으로 펼친 값
    let transform: [Double]
    
    //신뢰도가 낮아 다시 스캔하면 좋을 항목인지
    var isLowConfidence: Bool {
        confidence == "low"
    }
}

extension Array where Element == CapturedFurniture {
    //SwiftData에 문자열로 저장하기 위해 JSON으로 직렬화
    func encodedJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    //저장된 JSON 문자열을 가구 목록으로 복원
    static func decoded(from json: String?) -> [CapturedFurniture] {
        guard let json, let data = json.data(using: .utf8),
              let furniture = try? JSONDecoder().decode([CapturedFurniture].self, from: data) else {
            return []
        }
        return furniture
    }
}
