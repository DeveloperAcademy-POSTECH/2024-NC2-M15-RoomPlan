//
//  SpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//보관함 목록에서 보여지는 간략한 정보를 담은 공간 카드 뷰
//신규 보관함과 레거시 보관함이 함께 사용한다
struct SpaceCellView: View {
    let space: SpaceData
    
    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 153, height: 272)
            .foregroundStyle(Color.white)
            .overlay(
                ZStack {
                    //배경 이미지 데이터가 손상된 경우 크래시 대신 단색 배경으로 대체
                    if let backgroundData = space.background, let backgroundImage = UIImage(data: backgroundData) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 153, height: 272)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                    } else if let previewData = space.previewImageData, let preview = UIImage(data: previewData) {
                        //배경 사진을 넣지 않은 카드는 모델 썸네일로 대신 보여준다
                        Color.black
                            .frame(width: 153, height: 272)
                            .cornerRadius(19)
                        
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130)
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
