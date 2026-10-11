//
//  CommentPopupView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI

//장소 입력 팝업창
struct CommentPopupView: View {
    let initialComment: String
    let onComplete: (String) -> Void

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
            }
            .submitLabel(.done)
            .focused($focusState)
            .foregroundStyle(Color.black)
            .padding()
            .onAppear(perform: {
                typedComment = initialComment
                focusState = true
            })

            TextButtonCapsule(text: "완료", color: .gray) {
                onComplete(typedComment)
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

#Preview {
    CommentPopupView(initialComment: "", onComplete: { _ in })
}
