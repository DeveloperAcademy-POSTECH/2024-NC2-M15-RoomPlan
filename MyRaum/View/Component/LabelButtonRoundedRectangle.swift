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
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangleButtonLabel(text: text, systemImage: image, height: 40, cornerRadius: 8)
        }
    }
}

#Preview {
    LabelButtonRoundedRectangle(text: "공유", image: "square.and.arrow.up", action: {})
        .padding()
}
