//
//  SettingsView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ScrollView {
                navigationCell(title: "언어 설정") {
                    LanguageSettingView()
                }
                
                navigationCell(title: "My Raum을 만든 사람들") {
                    InfoView()
                }
            }
            
            Spacer()
            
            Text("[Version \(AppEnvironment.version)]")
                .foregroundStyle(Color.gray)
                .font(.caption)
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
                Text("설정")
                    .bold()
            }
        }
    }
}

private extension SettingsView {
    func navigationCell<T: View>(title: LocalizedStringKey, @ViewBuilder destination: @escaping () -> T) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                }
                .bold()
                .padding(.vertical, 16)
                
                Divider()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
