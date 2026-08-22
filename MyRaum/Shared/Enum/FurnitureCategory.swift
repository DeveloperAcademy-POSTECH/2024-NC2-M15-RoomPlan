//
//  FurnitureCategory.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//RoomPlan의 가구 카테고리를 사람이 읽을 수 있는 이름으로 바꾸는 역할 (8.2)
enum FurnitureCategory {
    private static let names: [String: String] = [
        "bathtub": "욕조",
        "bed": "침대",
        "chair": "의자",
        "dishwasher": "식기세척기",
        "fireplace": "벽난로",
        "oven": "오븐",
        "refrigerator": "냉장고",
        "sink": "싱크대",
        "sofa": "소파",
        "stairs": "계단",
        "storage": "수납장",
        "stove": "스토브",
        "table": "테이블",
        "television": "TV",
        "toilet": "변기",
        "washerDryer": "세탁기"
    ]
    
    //번역 키를 돌려주는 함수. 모르는 카테고리는 원본 문자열을 그대로 쓴다
    static func displayNameKey(for category: String) -> String {
        names[category] ?? category
    }
}
