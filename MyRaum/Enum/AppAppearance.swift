//
//  AppAppearance.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//앱의 화면 모드 - 시스템 설정을 따르거나 라이트/다크 모드로 고정
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "시스템 설정"
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        }
    }

    //시트, 전체 화면 등 앱의 모든 화면에 적용되도록 윈도우 단위로 설정
    @MainActor
    func apply() {
        let style: UIUserInterfaceStyle = switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}
