//
//  GrayLabelButton.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct GrayLabelButton: View {
    let text: String
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
    GrayLabelButton(text: "공유", image: "square.and.arrow.up", action: {})
        .padding()
}
