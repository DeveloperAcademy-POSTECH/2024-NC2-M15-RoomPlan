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
    enum Key {
        static let language = "selectedLanguage"
        //1.1.2까지 사용한 화면 모드 설정 - 앱이 다크 모드로 고정되면서 사용하지 않음 (남아 있는 값을 지울 때만 사용)
        static let legacyAppearance = "appearance"
        static let haptics = "hapticsEnabled"
        static let savesLocation = "savesLocation"
    }

    var language: AppLanguage {
        didSet {
            if language == .system {
                UserDefaults.standard.removeObject(forKey: Key.language)
            } else {
                UserDefaults.standard.set(language.rawValue, forKey: Key.language)
            }
        }
    }
    
    //버튼, 탭 등을 누를 때 햅틱 피드백을 줄지 여부
    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: Key.haptics)
        }
    }

    //새로 저장하는 공간 카드에 스캔한 위치를 함께 저장할지 여부
    var savesLocation: Bool {
        didSet {
            UserDefaults.standard.set(savesLocation, forKey: Key.savesLocation)
        }
    }

    init() {
        self.hapticsEnabled = UserDefaults.standard.object(forKey: Key.haptics) as? Bool ?? true
        self.savesLocation = UserDefaults.standard.object(forKey: Key.savesLocation) as? Bool ?? true
        if let savedLanguage = UserDefaults.standard.string(forKey: Key.language), !savedLanguage.isEmpty {
            self.language = AppLanguage(rawValue: savedLanguage) ?? .system
        } else {
            self.language = .system
        }
        UserDefaults.standard.removeObject(forKey: Key.legacyAppearance)
    }
    
    var effectiveLocale: Locale {
        if language == .system {
            return Locale.autoupdatingCurrent
        } else {
            return Locale(identifier: language.rawValue)
        }
    }
}
