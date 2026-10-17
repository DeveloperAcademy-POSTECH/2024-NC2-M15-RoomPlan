//
//  MyPageView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct MyPageView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ScrollView {
                VStack(alignment: .leading) {
                    myPageSection(title: "설정") {
                        navigationCell(title: "언어 설정") {
                            LanguageSettingView()
                        }
                    }
                    
                    myPageSection(title: "앱 정보") {
                        navigationCell(title: "My Raum을 만든 사람들") {
                            InfoView()
                        }
                    }
                }
            }
            
            Spacer()
            
            Text("[Version \(AppEnvironment.version)]")
                .foregroundStyle(Color.gray)
                .font(.caption)
                //탭바에 너무 붙지 않도록 여백
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .customNavigationBar(title: "내 정보", showsBackButton: false)
    }
}

private extension MyPageView {
    func myPageSection<T: View>(title: LocalizedStringKey, @ViewBuilder items: @escaping () -> T) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(Color.gray)
            
            items()
                .padding(.vertical, 16)
            
            Divider()
        }
        .padding(.vertical, 8)
    }
    
    func navigationCell<T: View>(title: LocalizedStringKey, @ViewBuilder destination: @escaping () -> T) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .bold()
        }
        .hapticOnTap()
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
