//
//  SpaceShareCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//이미지 저장·공유용으로 카드를 정지 이미지로 그리는 뷰
//RealityView는 drawHierarchy로 캡쳐되지 않으므로 3D 대신 저장된 썸네일을 사용한다
struct SpaceShareCardView: View {
    let space: SpaceData
    
    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 315, height: 560)
            .foregroundColor(.white)
            .overlay(
                ZStack {
                    if let backgroundData = space.background, let backgroundImage = UIImage(data: backgroundData) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 315, height: 560)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                    } else {
                        Color.grayButton
                            .frame(width: 315, height: 560)
                            .cornerRadius(19)
                    }
                    
                    VStack {
                        Label {
                            Text(space.comment)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        } icon: {
                            Image("locationpin")
                                .resizable()
                                .frame(width:17, height:21)
                        }
                        .padding(.top, 30)
                        
                        Spacer()
                        
                        if let thumbnailData = space.thumbnail, let thumbnail = UIImage(data: thumbnailData) {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFit()
                        }
                        
                        Spacer()
                        
                        HStack {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                                .padding()
                                .opacity(0.4)
                            
                            Spacer()
                            
                            Text(space.displayDate)
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                                .padding()
                        }
                        .padding(.bottom, 20)
                    }
                }
            )
    }
}
