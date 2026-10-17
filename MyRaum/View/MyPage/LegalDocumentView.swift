//
//  LegalDocumentView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//앱에 포함된 약관 문서 (Resources/Legal의 마크다운 파일)
enum LegalDocument {
    case privacyPolicy
    case termsOfService

    var title: LocalizedStringKey {
        switch self {
        case .privacyPolicy: return "개인정보처리방침"
        case .termsOfService: return "이용약관"
        }
    }

    //언어별 파일 이름은 "\(fileName)_ko.md", "\(fileName)_en.md"
    var fileName: String {
        switch self {
        case .privacyPolicy: return "privacy_policy"
        case .termsOfService: return "terms_of_service"
        }
    }

    //앱 언어가 한국어면 한국어 문서, 그 외에는 영어 문서
    func markdown(for locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier == "ko" ? "ko" : "en"
        guard let url = Bundle.main.url(forResource: "\(fileName)_\(language)", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return text
    }
}

//개인정보처리방침, 이용약관을 보여주는 화면
struct LegalDocumentView: View {
    @Environment(AppSettingsManager.self) private var appSettingsManager

    let document: LegalDocument

    var body: some View {
        ScrollView {
            //문서 전체를 하나의 카드 안에 표시
            MarkdownView(markdown: document.markdown(for: appSettingsManager.effectiveLocale))
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .customNavigationBar(title: document.title)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
    .environment(AppSettingsManager())
}
