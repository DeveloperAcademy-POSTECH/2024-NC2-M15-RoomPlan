//
//  ContentView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//앱 메인화면 (홈 탭)
struct ContentView: View {
    let onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()

            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 280)
                .padding(.leading, 30)
                .padding(.bottom, 30)

            Text("나의 공간을 기록해보세요.")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .padding(.leading, 30)
                .padding(.bottom, 30)

            //공간 스캔 화면으로 이동
            TextButtonCapsule(text: "스캔하기", color: .white) {
                onScan()
            }
            .padding(.leading, 30)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        //검은 배경과 어울리도록 홈 탭에서는 탭바를 어둡게 표시
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    ContentView(onScan: {})
}
