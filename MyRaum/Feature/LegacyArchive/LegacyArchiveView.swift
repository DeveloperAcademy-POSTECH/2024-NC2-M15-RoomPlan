//
//  LegacyArchiveView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//1.0.x에서 이미지로 저장된 카드만 모아 보여주는 조회 전용 보관함 (D-05)
struct LegacyArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        LegacyArchiveContentView()
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .bold()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("이전 카드")
                        .bold()
                }
            }
    }
}
