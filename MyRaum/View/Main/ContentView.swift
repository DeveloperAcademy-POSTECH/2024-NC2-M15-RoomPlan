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

            //공간 스캔 화면으로 이동
            TextButtonCapsule(text: "스캔하기", color: .adaptive(colorScheme, dark: .white)) {
                onScan()
            }
            .padding(.leading, 30)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    ContentView(onScan: {})
}
