//
//  ContentView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//앱 메인화면 (홈 탭)
//다크 모드에서는 검은 배경에 밝은 로고, 라이트 모드에서는 흰 배경에 어두운 로고를 보여줌
struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    //홈 화면이 나타날 때 문구와 버튼이 차례로 떠오르는 애니메이션
    @State private var showsText: Bool = false
    @State private var showsButton: Bool = false

    let onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()

            //라이트/다크 모드에 따라 로고 색이 바뀌는 이미지 (Assets의 homelogo)
            Image("homelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 280)
                .padding(.leading, 30)
                .padding(.bottom, 30)

            Text("나의 공간을 기록해보세요.")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.leading)
                .padding(.leading, 30)
                .padding(.bottom, 30)
                .opacity(showsText ? 1 : 0)
                .offset(y: showsText ? 0 : 12)

            //공간 스캔 화면으로 이동
            TextButtonCapsule(text: "스캔하기", color: .adaptive(colorScheme, dark: .white)) {
                onScan()
            }
            //버튼이 천천히 숨 쉬듯 커졌다 작아지며 스캔을 유도함
            .phaseAnimator(reduceMotion ? [1] : [1, 1.04]) { content, scale in
                content.scaleEffect(scale)
            } animation: { _ in
                .easeInOut(duration: 1.8)
            }
            .padding(.leading, 30)
            .opacity(showsButton ? 1 : 0)
            .offset(y: showsButton ? 0 : 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !reduceMotion else {
                showsText = true
                showsButton = true
                return
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                showsText = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.45)) {
                showsButton = true
            }
        }
        .onDisappear {
            //다른 탭에 갔다가 돌아오면 다시 애니메이션이 보이도록 초기화
            showsText = false
            showsButton = false
        }
    }
}

#Preview {
    ContentView(onScan: {})
}
