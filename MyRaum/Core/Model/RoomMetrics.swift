//
//  RoomMetrics.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//스캔 결과에서 뽑아낸 공간의 수치 정보
struct RoomMetrics {
    //바닥 면적 (m²)
    let floorAreaSqM: Double?
    //가구 카테고리 조합으로 추론한 방 종류
    let roomType: RoomTypeGuess
    //인식된 가구 목록
    let furniture: [CapturedFurniture]
    
    //신뢰도가 낮은 항목 수 — 스캔 품질 지표로 사용
    var lowConfidenceCount: Int {
        furniture.filter(\.isLowConfidence).count
    }
}

//가구 조합으로 추론한 방 종류
enum RoomTypeGuess: String, CaseIterable {
    case bedroom
    case kitchen
    case livingRoom
    case bathroom
    case unknown
    
    //카드에 표시할 이름
    var displayNameKey: String {
        switch self {
        case .bedroom: return "침실"
        case .kitchen: return "주방"
        case .livingRoom: return "거실"
        case .bathroom: return "욕실"
        case .unknown: return "공간"
        }
    }
}
