//
//  View+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 6/30/24.
//

import SwiftUI

//MySpaceCardView를 이미지로 변환하여 저장 및 공유하기 위한 View Extension
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize

        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

//뒤로가기 버튼과 타이틀로 구성된 공통 네비게이션 바
//탭의 첫 화면처럼 돌아갈 화면이 없으면 showsBackButton을 false로 설정
extension View {
    func customNavigationBar(title: LocalizedStringKey, showsBackButton: Bool = true) -> some View {
        customNavigationBar(title: title, showsBackButton: showsBackButton) {
            EmptyView()
        }
    }

    func customNavigationBar<Trailing: View>(title: LocalizedStringKey, showsBackButton: Bool = true, @ViewBuilder trailing: () -> Trailing) -> some View {
        modifier(CustomNavigationBarModifier(title: title, showsBackButton: showsBackButton, trailing: trailing()))
    }
}

private struct CustomNavigationBarModifier<Trailing: View>: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let showsBackButton: Bool
    let trailing: Trailing

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            //탭의 첫 화면에서 큰 타이틀 영역만큼 여백이 생기지 않도록 함
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsBackButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            HapticManager.tap()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .bold()
                        }
                    }
                }

                //탭의 첫 화면은 타이틀을 왼쪽에 크게, 그 외 화면은 가운데에 표시
                if showsBackButton {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .bold()
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(title)
                            .font(.title2)
                            .bold()
                            .fixedSize()
                    }
                    .hiddenSharedBackground()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailing
                }
            }
            //스크롤된 내용이 상단 툴바 아래로 지나갈 때 배경이 그라데이션처럼 서서히 불투명해지도록 함
            .softTopScrollEdge()
    }
}

private extension ToolbarContent {
    //iOS 26부터 툴바 항목에 기본으로 생기는 유리 배경을 숨겨 타이틀이 글자만 보이도록 함
    @ToolbarContentBuilder
    func hiddenSharedBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

private extension View {
    //scrollEdgeEffectStyle은 iOS 26부터 지원하므로 이전 버전에서는 기존 모습을 유지
    @ViewBuilder
    func softTopScrollEdge() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}

//언어 설정, 화면 모드, 내 정보 화면의 셀 높이를 통일
extension View {
    func settingCellHeight() -> some View {
        frame(maxWidth: .infinity, minHeight: 70, maxHeight: 70)
    }
}
