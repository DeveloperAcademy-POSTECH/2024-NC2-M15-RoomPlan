//
//  ScanAddInfoView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//방 모델 이미지 + 배경 이미지 + 장소명 화면
struct ScanAddInfoView: View {
    @Bindable var viewModel: ScanFlowViewModel
    
    var body: some View {
        ZStack {
            VStack {
                Text("결과물을 확인하세요.")
                    .bold()
                    .padding()
                
                NewCardView(
                    model: $viewModel.model,
                    background: $viewModel.background,
                    date: $viewModel.dateString,
                    comment: $viewModel.comment
                )
                
                Spacer()
                
                HStack(spacing: 16) {
                    TextButtonRoundedRectangle(text: "장소 수정하기") {
                        viewModel.showCommentPopup = true
                    }
                    
                    TextButtonRoundedRectangle(text: "미리보기") {
                        viewModel.moveToFinalResult()
                    }
                }
                .padding(.horizontal, 16)
            }
            
            if viewModel.showCommentPopup {
                CommentPopupOverlay(viewModel: viewModel)
            }
        }
    }
}
