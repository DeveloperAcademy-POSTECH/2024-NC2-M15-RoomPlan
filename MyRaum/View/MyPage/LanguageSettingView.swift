//
//  LanguageSettingView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/16/25.
//

import SwiftUI

struct LanguageSettingView: View {
    @Environment(AppSettingsManager.self) private var appSettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLanguage: AppLanguage = .system
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(AppLanguage.allCases) { lang in
                VStack(spacing: 0) {
                    HStack {
                        Text(LocalizedStringKey(lang.displayName))
                        
                        Spacer()
                        
                        if lang == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary)
                        }
                    }
                    .bold()
                    .settingCellHeight()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticManager.selection()
                        selectedLanguage = lang
                    }
                    
                    Divider()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .customNavigationBar(title: "언어 설정") {
            Button {
                HapticManager.tap()
                appSettingsManager.language = selectedLanguage
                dismiss()
            } label: {
                Text("저장")
            }
        }
        .onAppear {
            selectedLanguage = appSettingsManager.language
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingView()
    }
    .environment(AppSettingsManager())
}
