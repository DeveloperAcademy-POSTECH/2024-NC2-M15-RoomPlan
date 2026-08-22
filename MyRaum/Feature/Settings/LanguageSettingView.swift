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
        VStack(alignment: .leading) {
            ForEach(AppLanguage.allCases) { lang in
                VStack {
                    HStack {
                        Text(LocalizedStringKey(lang.displayName))
                        
                        Spacer()
                        
                        if lang == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary)
                        }
                    }
                    .bold()
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLanguage = lang
                    }
                    
                    Divider()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .bold()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("언어 설정")
                    .bold()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appSettingsManager.language = selectedLanguage
                    dismiss()
                } label: {
                    Text("저장")
                }
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
}
