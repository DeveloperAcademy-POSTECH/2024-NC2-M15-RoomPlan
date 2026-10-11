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
extension View {
    func customNavigationBar(title: LocalizedStringKey) -> some View {
        customNavigationBar(title: title) {
            EmptyView()
        }
    }

    func customNavigationBar<Trailing: View>(title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing) -> some View {
        modifier(CustomNavigationBarModifier(title: title, trailing: trailing()))
    }
}

private struct CustomNavigationBarModifier<Trailing: View>: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let trailing: Trailing

    func body(content: Content) -> some View {
        content
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
                    Text(title)
                        .bold()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailing
                }
            }
    }
}
