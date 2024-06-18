//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

struct MySpaceCellView: View {
    @State private var comment: String = "체인지업그라운드"
    @State private var background: Image = Image(systemName: "person")
    
    var body: some View {
        //위에 있는 더미 변수로 카드 만들어주셔용~나중에 데이터 연결은 제가 합니당
        
        ZStack {
            Rectangle()
                .frame(width: 169, height: 262)
                .cornerRadius(19)
                .foregroundColor(.white)
                .overlay(
                    ZStack {
                        Image("bg")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 169, height: 262)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.gray, lineWidth: 2)
                    }
                )
                .padding(.trailing, 170)
                .padding(.bottom, 300)
            
            Path { path in
                path.move(to: CGPoint(x : 100, y : 200))
                path.addLine (to : CGPoint(x: 100, y : 200))
                path.addLine (to : CGPoint(x: 55, y : 200))
                path.addLine (to : CGPoint(x: 100, y : 150))
            }
            .fill(Color(.sRGB, white: 0.8, opacity: 1))
            .offset(x: 97, y: 161.5)
        }
        
        
        
    }
}

#Preview {
    MySpaceCellView()
}
