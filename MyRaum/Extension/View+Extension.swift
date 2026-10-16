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
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .bold()
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .bold()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailing
                }
            }
    }
}
