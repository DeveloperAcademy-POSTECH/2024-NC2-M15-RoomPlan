//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//보관함 목록에서 보여지는 간략한 정보를 담은 공간 카드 뷰
struct MySpaceCellView: View {
    let space: SpaceData
    
    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 153, height: 272)
            .foregroundStyle(Color.white)
            .overlay(
                ZStack {
                    //배경 이미지 데이터가 손상된 경우 크래시 대신 단색 배경으로 대체
                    if let backgroundImage = UIImage(data: space.background) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 153, height: 272)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                    } else {
                        Color.grayButton
                            .frame(width: 153, height: 272)
                            .cornerRadius(19)
                    }
                    
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
