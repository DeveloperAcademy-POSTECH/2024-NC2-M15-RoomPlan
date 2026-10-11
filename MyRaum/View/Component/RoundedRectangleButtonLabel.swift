//
//  RoundedRectangleButtonLabel.swift
//  MyRaum
//
//  Created by Yune Cho on 10/11/26.
//

import SwiftUI

//둥근 사각형 버튼의 라벨
//Button 외에 PhotosPicker, ShareLink 등의 라벨로도 사용할 수 있도록 분리
struct RoundedRectangleButtonLabel: View {
    let text: LocalizedStringKey
    var systemImage: String? = nil
    var height: CGFloat = 60
    var cornerRadius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(Color.grayButtonStroke)
            .frame(height: height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(Color.grayButton)

                Group {
                    if let systemImage {
                        Label(text, systemImage: systemImage)
                    } else {
                        Text(text)
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(Color.white)
            }
    }
}

#Preview {
    VStack {
        RoundedRectangleButtonLabel(text: "배경 추가하기")
        RoundedRectangleButtonLabel(text: "공유", systemImage: "square.and.arrow.up", height: 40, cornerRadius: 8)
    }
    .padding()
}
