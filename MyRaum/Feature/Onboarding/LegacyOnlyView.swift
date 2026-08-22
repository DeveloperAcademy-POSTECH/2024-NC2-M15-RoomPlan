//
//  LegacyOnlyView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//로그인 없이 예전 카드만 보는 제한 모드 (6A.5)
//가능: 조회·이미지 저장·공유·삭제 / 불가: 신규 스캔·3D 카드·지도·공개 설정
struct LegacyOnlyView: View {
    let onRequestSignIn: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modeBanner
                
                LegacyArchiveContentView()
            }
            .navigationTitle("이전 카드")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension LegacyOnlyView {
    //현재 모드를 알리고 언제든 로그인할 수 있는 진입점을 상시 노출한다
    var modeBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("이전 카드 보기 모드")
                    .font(.footnote)
                    .bold()
                
                Text("스캔과 지도를 사용하려면 로그인이 필요합니다.")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            Spacer()
            
            Button {
                onRequestSignIn()
            } label: {
                Text("로그인")
                    .font(.footnote)
                    .bold()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.grayButton.opacity(0.2))
    }
}
