//
//  CommentPopupView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI

struct CommentPopupView: View {
    @Binding var showCommentPopup: Bool
    @Binding var currentPage: Int
    @Binding var comment: String
    
    @State private var typedComment: String = ""
    
    @FocusState private var focusState: Bool
    
    var body: some View {
        VStack {
            Text("공간에 대한 한줄평을 기록하세요.")
                .bold()
                .foregroundStyle(Color.black)
            
            TextField(text: $typedComment) {
                Text("코멘트를 입력하세요.")
                    .foregroundStyle(Color.gray)
                    .padding(.leading)
                    .submitLabel(.done)
                    .onAppear(perform: {
                        focusState = true
                    })
            }
            .padding()
            
            Button(action: {
                comment = typedComment
                currentPage = 2
                showCommentPopup = false
            }, label: {
                Image("finish")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150)
            })
            .padding()
        }
        .frame(width: 300, height: 180)
        .background {
            Rectangle()
                .foregroundStyle(Color.white)
                .frame(width: 300, height: 200)
                .cornerRadius(30)
        }
    }
}

#Preview {
    CommentPopupView(showCommentPopup: .constant(true), currentPage: .constant(1), comment: .constant(""))
}
