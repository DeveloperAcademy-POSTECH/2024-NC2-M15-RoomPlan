//
//  TextButtonRoundedRectangle.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct TextButtonRoundedRectangle: View {
    let text: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            RoundedRectangleButtonLabel(text: text)
        }
    }
}

#Preview {
    TextButtonRoundedRectangle(text: "저장하기", action: {})
        .padding()
}
