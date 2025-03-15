//
//  CommentPopupView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI

//장소 입력 팝업창
struct CommentPopupView: View {
    @Binding var showCommentPopup: Bool
    @Binding var currentPage: Int
    @Binding var comment: String
    
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
            
            Button(action: {
                comment = typedComment
                currentPage = 2
                showCommentPopup = false
            }, label: {
                Image("finish")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160)
            })
            .padding(.top)
        }
        .frame(width: 350, height: 180)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .foregroundStyle(Color.white)
                .frame(width: 350, height: 180)
        }
    }
}

#Preview {
    CommentPopupView(showCommentPopup: .constant(true), currentPage: .constant(1), comment: .constant(""))
}
