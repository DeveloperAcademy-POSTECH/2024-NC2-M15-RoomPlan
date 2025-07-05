//
//  TextButtonCapsule.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct TextButtonCapsule: View {
    let text: String
    let color: ButtonColor
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(color.color())
                .frame(width: 145, height: 40)
                .overlay {
                    Text(text)
                        .font(.system(size: 18))
                        .foregroundStyle(color.color() == .white ? Color.black : Color.white)
                }
        }
    }
}

#Preview {
    TextButtonCapsule(text: "스캔하기", color: .gray, action: {})
}
