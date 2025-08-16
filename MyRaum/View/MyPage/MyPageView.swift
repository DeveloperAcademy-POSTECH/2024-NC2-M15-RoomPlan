//
//  MyPageView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                Text("내 정보")
                    .bold()
            }
        }
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
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
