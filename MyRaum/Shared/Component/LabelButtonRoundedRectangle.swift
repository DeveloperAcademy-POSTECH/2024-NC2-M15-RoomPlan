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
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.grayButtonStroke)
                .frame(height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(Color.grayButton)
                    
                    Label(text, systemImage: image)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                }
        }
    }
}

#Preview {
    LabelButtonRoundedRectangle(text: "공유", image: "square.and.arrow.up", action: {})
        .padding()
}
