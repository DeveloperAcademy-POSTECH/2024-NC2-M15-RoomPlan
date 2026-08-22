//
//  MyPageView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    
    @State private var showSignOutConfirmation: Bool = false
    @State private var showDeleteAccountConfirmation: Bool = false
    @State private var deleteAccountError: String?
    
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
                    
                    myPageSection(title: "계정") {
                        VStack(alignment: .leading, spacing: 24) {
                            actionCell(title: "로그아웃") {
                                showSignOutConfirmation = true
                            }
                            
                            actionCell(title: "계정 삭제", isDestructive: true) {
                                showDeleteAccountConfirmation = true
                            }
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
        .alert("로그아웃하시겠습니까?", isPresented: $showSignOutConfirmation) {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }
            
            Button(role: .destructive) {
                Task {
                    await router.signOut()
                }
            } label: {
                Text("로그아웃")
            }
        }
        .alert("계정을 삭제하시겠습니까?", isPresented: $showDeleteAccountConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }
            
            Button(role: .destructive) {
                Task {
                    do {
                        try await router.deleteAccount()
                    } catch {
                        deleteAccountError = error.localizedDescription
                    }
                }
            } label: {
                Text("삭제")
            }
        }, message: {
            Text("서버에 저장된 공간이 모두 삭제되며 되돌릴 수 없습니다. 이 기기의 이전 카드는 남습니다.")
        })
        .alert("계정을 삭제하지 못했습니다.", isPresented: .constant(deleteAccountError != nil)) {
            Button {
                deleteAccountError = nil
            } label: {
                Text("확인")
            }
        }
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
    
    //탭하면 동작만 수행하는 셀
    func actionCell(title: LocalizedStringKey, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(isDestructive ? Color.red : Color.primary)
                
                Spacer()
            }
            .bold()
            .contentShape(Rectangle())
        }
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
