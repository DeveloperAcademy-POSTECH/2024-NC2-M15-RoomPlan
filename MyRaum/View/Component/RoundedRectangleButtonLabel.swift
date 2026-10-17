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
    var color: ButtonColor = .gray

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(color.strokeColor)
            .frame(height: height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(color.color())

                Group {
                    if let systemImage {
                        Label(text, systemImage: systemImage)
                    } else {
                        Text(text)
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(color.textColor)
            }
            //배경이 투명한 버튼도 전체 영역을 탭할 수 있도록 함
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack {
        RoundedRectangleButtonLabel(text: "배경 추가하기")
        RoundedRectangleButtonLabel(text: "공유", systemImage: "square.and.arrow.up", height: 40, cornerRadius: 8)
    }
    .padding()
}
