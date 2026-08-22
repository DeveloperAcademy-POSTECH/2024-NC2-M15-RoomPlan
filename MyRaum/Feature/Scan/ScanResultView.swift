//
//  ScanResultView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import PhotosUI

//방 모델 이미지 + 배경 이미지 화면
struct ScanResultView: View {
    @Bindable var viewModel: ScanFlowViewModel
    
    var body: some View {
        ZStack {
            VStack {
                Text("장소를 입력하세요.")
                    .bold()
                    .padding()
                
                NewCardView(
                    model: $viewModel.thumbnail,
                    background: $viewModel.background,
                    date: $viewModel.dateString,
                    comment: $viewModel.comment
                )
                
                Spacer()
                
                HStack(spacing: 16) {
                    PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.grayButtonStroke)
                            .frame(height: 60)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .foregroundStyle(Color.grayButton)
                                
                                Text("배경 수정하기")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white)
                            }
                    }
                    .onChange(of: viewModel.selectedItem) {
                        Task {
                            await viewModel.loadBackground()
                        }
                    }
                    
                    TextButtonRoundedRectangle(text: "장소 입력하기") {
                        viewModel.showCommentPopup = true
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
