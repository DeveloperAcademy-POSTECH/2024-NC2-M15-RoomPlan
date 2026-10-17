//
//  HapticManager.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//버튼, 탭 등을 누를 때 주는 햅틱 피드백
@MainActor
enum HapticManager {
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    //일반 버튼을 눌렀을 때
    static func tap() {
        impactGenerator.impactOccurred()
    }

    //탭, 항목 선택처럼 선택 상태가 바뀔 때
    static func selection() {
        selectionGenerator.selectionChanged()
    }

    //저장 완료, 삭제 확인처럼 결과를 알려줄 때
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
}

extension View {
    //NavigationLink, ShareLink, PhotosPicker처럼 action을 받지 않는 버튼에 햅틱 피드백을 추가
    func hapticOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded {
            HapticManager.tap()
        })
    }
}
