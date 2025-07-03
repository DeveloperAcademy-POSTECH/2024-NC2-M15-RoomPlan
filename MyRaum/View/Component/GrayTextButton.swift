//
//  GrayTextButton.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct GrayTextButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1))
                .foregroundStyle(Color.grayButtonStroke)
                .frame(height: 63)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color.grayButton)
                    
                    Text(text)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                }
        }
    }
}

#Preview {
    GrayTextButton(text: "저장하기", action: {})
        .padding()
}
