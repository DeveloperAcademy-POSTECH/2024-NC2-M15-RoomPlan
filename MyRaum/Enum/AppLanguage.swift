//
//  AppLanguage.swift
//  MyRaum
//
//  Created by Yune Cho on 8/16/25.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = ""
    case en = "en"
    case ko = "ko"
    
    var id: String { rawValue.isEmpty ? "system" : rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .en: return "English"
        case .ko: return "한국어"
        }
    }
}
