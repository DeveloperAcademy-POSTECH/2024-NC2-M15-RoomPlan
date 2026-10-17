//
//  TextButtonCapsule.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct TextButtonCapsule: View {
    let text: LocalizedStringKey
    let color: ButtonColor
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(color.color())
                .frame(width: 145, height: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.strokeColor, lineWidth: 1)

                    Text(text)
                        .font(.system(size: 18))
                        .foregroundStyle(color.textColor)
                }
                //배경이 투명한 버튼도 전체 영역을 탭할 수 있도록 함
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    TextButtonCapsule(text: "스캔하기", color: .gray, action: {})
}
