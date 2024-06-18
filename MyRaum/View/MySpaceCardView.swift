//
//  MySpaceCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import SwiftUI

struct MySpaceCardView: View {
    @Binding var date: String?
    @Binding var model: UIImage?
    @Binding var background: UIImage?
    @Binding var comment: String?
    @Binding var music: String?
    
    var body: some View {
        ZStack {
            if let background {
                Image(uiImage: background)
                    .resizable()
                    .scaledToFit()
            }
            
            if let model {
                Image(uiImage: model)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("모델 없음")
            }
            
            VStack {
                if let comment {
                    Text(comment)
                }
                
                if let date {
                    Text(date)
                }
            }
        }
    }
}

//#Preview {
//    MySpaceCardView(date: .constant("2024년 6월 14일"), model: , background: .constant(Image("bg")), comment: .constant("체인지업그라운드"), music: .constant(""))
//}
