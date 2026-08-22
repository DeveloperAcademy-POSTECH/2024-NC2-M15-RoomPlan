//
//  CommentPopupView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI

//장소 입력 팝업창
struct CommentPopupView: View {
    let comment: String
    let onDone: (String) -> Void
    
    @State private var typedComment: String = ""
    
    @FocusState private var focusState: Bool
    
    var body: some View {
        VStack {
            Text("공간에 대해서 기록하세요.")
                .bold()
                .foregroundStyle(Color.black)
            
            TextField(text: $typedComment) {
                Text("장소를 입력하세요.")
                    .foregroundStyle(Color.gray)
                    .padding(.leading)
                    .submitLabel(.done)
            }
            .foregroundStyle(Color.black)
            .padding()
            .onAppear(perform: {
                if comment != "" {
                    typedComment = comment
                }
                focusState = true
            })
            
            TextButtonCapsule(text: "완료", color: .gray) {
                onDone(typedComment)
            }
        }
        .frame(width: 350, height: 180)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .foregroundStyle(Color.white)
                .frame(width: 350, height: 180)
        }
    }
}

//팝업 뒤의 어두운 배경까지 함께 그리는 오버레이
struct CommentPopupOverlay: View {
    let viewModel: ScanFlowViewModel
    
    var body: some View {
        Color.black
            .opacity(0.5)
            .ignoresSafeArea()
        
        CommentPopupView(comment: viewModel.comment) { newComment in
            viewModel.confirmComment(newComment)
        }
    }
}

#Preview {
    CommentPopupView(comment: "", onDone: { _ in })
}
