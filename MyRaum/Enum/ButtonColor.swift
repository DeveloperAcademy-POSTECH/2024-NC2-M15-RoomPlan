//
//  ButtonColor.swift
//  MyRaum
//
//  Created by Yune Cho on 7/5/25.
//

import SwiftUI

enum ButtonColor {
    case gray
    case white
    //배경 없이 검은 글씨와 테두리만 있는 버튼 (라이트 모드에서 화면 배경과 맞춤)
    case outlined
    
    func color() -> Color {
        switch self {
        case .gray:
            return Color.grayButton
        case .white:
            return Color.white
        case .outlined:
            return Color.clear
        }
    }
    
    var textColor: Color {
        switch self {
        case .gray:
            return Color.white
        case .white, .outlined:
            return Color.black
        }
    }
    
    var strokeColor: Color {
        switch self {
        case .gray:
            return Color.grayButtonStroke
        case .white:
            return Color.clear
        case .outlined:
            return Color.black
        }
    }
    
    //다크 모드에서는 기본 색상, 라이트 모드에서는 테두리 버튼
    static func adaptive(_ colorScheme: ColorScheme, dark: ButtonColor = .gray) -> ButtonColor {
        colorScheme == .dark ? dark : .outlined
    }
}
