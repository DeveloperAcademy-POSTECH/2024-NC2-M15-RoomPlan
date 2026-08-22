//
//  OnboardingView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//2.0의 핵심 변화를 소개하는 온보딩 (6A.2)
struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var page: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "cube.transparent",
            title: "공간을 3D 모델로 남깁니다",
            body: "스캔한 공간이 이미지가 아니라 3D 모델로 저장되어, 카드에서 직접 돌려볼 수 있습니다."
        ),
        OnboardingPage(
            image: "icloud.and.arrow.up",
            title: "스캔한 공간은 서버에 저장됩니다",
            body: "2.0에서 스캔한 모든 공간은 계정에 함께 저장되어 기기를 바꿔도 복원됩니다. 위치 정보도 함께 저장됩니다."
        ),
        OnboardingPage(
            image: "lock",
            title: "공개 여부는 직접 정합니다",
            body: "저장된 공간은 기본적으로 나만 볼 수 있습니다. 공개로 바꾸면 위치를 포함한 정보가 다른 사람에게도 보입니다."
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    onboardingPageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            TextButtonCapsule(text: page == pages.count - 1 ? "시작하기" : "다음", color: .white) {
                if page == pages.count - 1 {
                    onComplete()
                } else {
                    withAnimation {
                        page += 1
                    }
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
    }
}

private extension OnboardingView {
    func onboardingPageView(_ item: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: item.image)
                .font(.system(size: 64))
                .foregroundStyle(Color.white)
            
            Text(item.title)
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            
            Text(item.body)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: LocalizedStringKey
    let body: LocalizedStringKey
}
