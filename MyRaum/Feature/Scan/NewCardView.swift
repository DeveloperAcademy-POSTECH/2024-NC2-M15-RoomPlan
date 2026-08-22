//
//  MySpaceCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import SwiftUI

//공간 카드를 생성하는 단계에서 화면에 진행상황을 보여주는 뷰
struct NewCardView: View {
    @Binding var model: UIImage?
    @Binding var background: UIImage?
    @Binding var date: String?
    @Binding var comment: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 315, height: 560)
                .cornerRadius(19)
                .foregroundColor(.white)
                .overlay(
                    ZStack {
                        if let background {
                            Image(uiImage: background)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 315, height: 560)
                                .overlay(Color.black.opacity(0.4))
                                .cornerRadius(19)
                                .clipped()
                        }
                        
                        VStack {
                            HStack {
                                if comment != "" {
                                    Image("locationpin")
                                        .resizable()
                                        .frame(width:17, height:21)
                                    
                                    Text(comment)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 30)
                            
                            Spacer()
                            
                            if let model {
                                Image(uiImage: model)
                                    .resizable()
                                    .scaledToFit()
                            }
                            
                            Spacer()
                            
                            HStack {
                                if let date {
                                    Image("logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 30)
                                        .padding()
                                        .opacity(0.4)
                                    
                                    Spacer()
                                    
                                    Text(date)
                                        .font(.system(size: 23, weight: .semibold))
                                        .foregroundColor(Color.white.opacity(0.8))
                                        .padding()
                                } else {
                                    Color.clear
                                        .frame(height: 30)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.gray, lineWidth: 2)
                    }
                )
        }
    }
}
