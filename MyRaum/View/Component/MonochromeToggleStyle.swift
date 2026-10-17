//
//  MonochromeToggleStyle.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//앱의 흑백톤에 맞춘 토글
//켜지면 라이트 모드에서는 검은색, 다크 모드에서는 흰색 트랙이 되고, 꺼지면 회색 트랙
//라벨 영역은 탭해도 값이 바뀌지 않음
struct MonochromeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label

            Spacer(minLength: 0)

            Capsule()
                .fill(configuration.isOn ? Color.primary : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(configuration.isOn ? Color(.systemBackground) : Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                        .padding(3)
                }
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                //셀 전체가 아니라 토글을 탭했을 때만 값이 바뀜
                .contentShape(Capsule())
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(configuration.isOn ? Text("켬") : Text("끔"))
        //VoiceOver에서는 셀을 활성화해서 값을 바꿀 수 있도록 함
        .accessibilityAction {
            configuration.isOn.toggle()
        }
    }
}

extension ToggleStyle where Self == MonochromeToggleStyle {
    static var monochrome: MonochromeToggleStyle { MonochromeToggleStyle() }
}

#Preview {
    VStack {
        Toggle("햅틱 피드백", isOn: .constant(true))
        Toggle("위치 정보 저장", isOn: .constant(false))
    }
    .toggleStyle(.monochrome)
    .padding()
}
