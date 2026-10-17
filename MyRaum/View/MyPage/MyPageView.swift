//
//  MyPageView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct MyPageView: View {
    @Environment(AppSettingsManager.self) private var appSettingsManager

    var body: some View {
        @Bindable var appSettingsManager = appSettingsManager

        ScrollView {
            VStack(alignment: .leading) {
                myPageSection(title: "설정") {
                    navigationCell(title: "언어 설정", value: LocalizedStringKey(appSettingsManager.language.displayName)) {
                        LanguageSettingView()
                    }

                    navigationCell(title: "화면 모드", value: appSettingsManager.appearance.displayName) {
                        AppearanceSettingView()
                    }

                    toggleCell(title: "햅틱 피드백", isOn: $appSettingsManager.hapticsEnabled)

                    toggleCell(
                        title: "위치 정보 저장",
                        info: "위치 정보 저장을 켜면 새로 저장하는 공간 카드에 스캔한 위치를 함께 저장하고 지도에 표시합니다.",
                        isOn: $appSettingsManager.savesLocation
                    )
                }
                
                myPageSection(title: "앱 정보") {
                    navigationCell(title: "개인정보처리방침") {
                        LegalDocumentView(document: .privacyPolicy)
                    }

                    navigationCell(title: "이용약관") {
                        LegalDocumentView(document: .termsOfService)
                    }

                    navigationCell(title: "My Raum을 만든 사람들") {
                        InfoView()
                    }
                }

                //버전 정보는 섹션들 바로 아래에 표시
                Text("[Version \(AppEnvironment.version)]")
                    .foregroundStyle(Color.gray)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .customNavigationBar(title: "내 정보", showsBackButton: false)
    }
}

private extension MyPageView {
    func myPageSection<T: View>(title: LocalizedStringKey, @ViewBuilder items: @escaping () -> T) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(Color.gray)
            
            //섹션 안의 각 셀 아래에 구분선
            VStack(alignment: .leading, spacing: 0) {
                items()
                    .settingCellHeight()
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
            }
        }
        .padding(.vertical, 8)
    }
    
    func navigationCell<T: View>(title: LocalizedStringKey, value: LocalizedStringKey? = nil, @ViewBuilder destination: @escaping () -> T) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                
                Spacer()

                //현재 설정된 값
                if let value {
                    Text(value)
                        .fontWeight(.regular)
                        .foregroundStyle(Color.gray)
                }
                
                Image(systemName: "chevron.right")
            }
            .bold()
        }
        .hapticOnTap()
    }

    //앱 안에서 바로 켜고 끄는 설정
    //info가 있으면 타이틀 오른쪽의 물음표 버튼을 눌러 설명을 볼 수 있음
    func toggleCell(title: LocalizedStringKey, info: LocalizedStringKey? = nil, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 6) {
                Text(title)
                    .bold()

                if let info {
                    InfoPopoverButton(message: info)
                }
            }
        }
        .toggleStyle(.monochrome)
        .onChange(of: isOn.wrappedValue) {
            HapticManager.selection()
        }
    }
}

//탭하면 작은 말풍선으로 설명을 보여주는 물음표 버튼
private struct InfoPopoverButton: View {
    let message: LocalizedStringKey

    @State private var isPresented: Bool = false

    var body: some View {
        Button {
            HapticManager.tap()
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.gray)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented) {
            Text(message)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 240)
                .padding()
                //아이폰에서도 시트가 아닌 말풍선으로 표시
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .environment(AppSettingsManager())
}
