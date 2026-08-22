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
    
    func color() -> Color {
        switch self {
        case .gray:
            return Color.grayButton
        case .white:
            return Color.white
        }
    }
}
