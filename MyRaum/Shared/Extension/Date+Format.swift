//
//  Date+Format.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//공간 카드에 표시하고 저장하는 날짜 형식을 한 곳에서 관리하기 위한 extension
extension Date {
    private static let spaceCardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
    
    //yyyy.MM.dd 형식의 문자열로 변환
    var spaceCardFormatted: String {
        Date.spaceCardFormatter.string(from: self)
    }
}
