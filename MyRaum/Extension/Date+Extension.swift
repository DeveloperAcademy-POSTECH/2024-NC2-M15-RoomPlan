//
//  Date+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 10/11/26.
//

import Foundation

extension Date {
    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    //공간 카드에 표시되고 SpaceData.date에 저장되는 날짜 형식
    var cardDateString: String {
        Date.cardDateFormatter.string(from: self)
    }
}
