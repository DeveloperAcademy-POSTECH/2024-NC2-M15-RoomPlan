//
//  AppearanceSettingView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//화면 모드 설정 - 언어 설정처럼 값을 고른 뒤 저장 버튼을 누르면 적용됨
struct AppearanceSettingView: View {
    @Environment(AppSettingsManager.self) private var appSettingsManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAppearance: AppAppearance = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(AppAppearance.allCases) { appearance in
                VStack(spacing: 0) {
                    HStack {
                        Text(appearance.displayName)

                        Spacer()

                        if appearance == selectedAppearance {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary)
                        }
                    }
                    .bold()
                    .settingCellHeight()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.selection()
                        selectedAppearance = appearance
                    }

                    Divider()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .customNavigationBar(title: "화면 모드") {
            Button {
                HapticManager.tap()
                appSettingsManager.appearance = selectedAppearance
                dismiss()
            } label: {
                Text("저장")
            }
        }
        .onAppear {
            selectedAppearance = appSettingsManager.appearance
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingView()
    }
    .environment(AppSettingsManager())
}
