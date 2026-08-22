//
//  DateFormatTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//날짜 포맷이 기존과 동일한 yyyy.MM.dd 형식인지 확인하는 테스트
struct DateFormatTests {
    @Test("Date는 yyyy.MM.dd 형식의 문자열로 변환된다")
    func formatsAsYearMonthDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 22
        
        let date = Calendar.current.date(from: components)
        #expect(date?.spaceCardFormatted == "2026.08.22")
    }
}
