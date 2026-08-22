//
//  CloseScanButton.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//스캔 화면을 벗어나는 버튼
//드로어 제스처가 꺼져 있는 동안 유일한 탈출구이므로 두 단계 모두에 노출한다
struct CloseScanButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 36, height: 36)
                .background {
                    Circle().foregroundStyle(Color.black.opacity(0.45))
                }
        }
        .accessibilityLabel(Text("닫기"))
    }
}
