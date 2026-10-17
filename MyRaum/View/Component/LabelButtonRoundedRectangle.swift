//
//  LabelButtonRoundedRectangle.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct LabelButtonRoundedRectangle: View {
    let text: LocalizedStringKey
    let image: String
    var color: ButtonColor = .gray
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            RoundedRectangleButtonLabel(text: text, systemImage: image, height: 40, cornerRadius: 8, color: color)
        }
    }
}

#Preview {
    LabelButtonRoundedRectangle(text: "공유", image: "square.and.arrow.up", action: {})
        .padding()
}
