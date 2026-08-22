//
//  AppSettingsManager.swift
//  MyRaum
//
//  Created by Yune Cho on 8/16/25.
//

import Foundation
import SwiftUI

//앱 설정을 관리하는 클래스
@Observable
final class AppSettingsManager {
    var language: AppLanguage {
        didSet {
            if language == .system {
                UserDefaults.standard.removeObject(forKey: "selectedLanguage")
            } else {
                UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
            }
        }
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"), !savedLanguage.isEmpty {
            self.language = AppLanguage(rawValue: savedLanguage) ?? .system
        } else {
            self.language = .system
        }
    }
    
    var effectiveLocale: Locale {
        if language == .system {
            return Locale.autoupdatingCurrent
        } else {
            return Locale(identifier: language.rawValue)
        }
    }
}
