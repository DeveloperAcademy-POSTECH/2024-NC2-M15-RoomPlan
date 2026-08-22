//
//  ScanFinalResultView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//최종 결과 확인 화면
struct ScanFinalResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var viewModel: ScanFlowViewModel
    
    var body: some View {
        VStack {
            Text("결과물을 저장해보세요.")
                .bold()
                .padding()
            
            NewCardView(
                model: $viewModel.thumbnail,
                background: $viewModel.background,
                date: $viewModel.dateString,
                comment: $viewModel.comment
            )
            
            Spacer()
            
            TextButtonRoundedRectangle(text: "저장") {
                viewModel.saveSpaceData()
            }
            .padding(.horizontal, 16)
            .alert("저장되었습니다.", isPresented: $viewModel.showSavedSuccessAlert) {
                Button {
                    viewModel.resetAfterSave()
                    dismiss()
                } label: {
                    Text("확인")
                }
            }
            .alert("저장하지 못했습니다.", isPresented: $viewModel.showSavedFailureAlert) {
                Button {
                    viewModel.resetAfterSave()
                    dismiss()
                } label: {
                    Text("확인")
                }
            }
        }
    }
}
