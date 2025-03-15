//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//보관함 목록에서 보여지는 간략한 정보를 담은 공간 카드 뷰
struct MySpaceCellView: View {
    var space: SpaceData
    
    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 153, height: 272)
            .foregroundStyle(Color.white)
            .overlay(
                ZStack {
                    Image(uiImage: UIImage(data: space.background)!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 153, height: 272)
                        .overlay(Color.black.opacity(0.4))
                        .cornerRadius(19)
                        .clipped()
                    
                    Label {
                        Text(space.comment)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    } icon: {
                        Image("locationpin")
                            .resizable()
                            .frame(width:17, height:21)
                    }
                }
            )
    }
}
