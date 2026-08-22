//
//  MySpaceCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import SwiftUI
import MapKit

//MySpaceDetailView에 보이는 카드 부분을 그린 뷰
struct MySpaceCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let space: SpaceData
    @Binding var cardFlipped: Bool
    
    var body: some View {
        switch cardFlipped {
        case true:
            cardBackView
        case false:
            cardFrontView
        }
    }
}

private extension MySpaceCardView {
    //카드의 앞면 - 스캔된 모델, 배경이미지, 장소명, 날짜 등이 노출됨
    var cardFrontView: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 315, height: 560)
            .foregroundColor(.white)
            .overlay(
                ZStack {
                    //배경 이미지 데이터가 손상된 경우 크래시 대신 단색 배경으로 대체
                    if let backgroundImage = UIImage(data: space.background) {
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
                        
                        //모델 이미지 데이터가 손상된 경우 크래시 대신 대체 아이콘 노출
                        if let modelImage = UIImage(data: space.model) {
                            Image(uiImage: modelImage)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "cube.transparent")
                                .resizable()
                                .scaledToFit()
                                .padding(60)
                                .foregroundStyle(Color.white.opacity(0.5))
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
                            
                            Text(space.date)
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                                .padding()
                        }
                        .padding(.bottom, 20)
                    }
                }
            )
            .onTapGesture {
                withAnimation(Animation.linear(duration: 0.8)) {
                    cardFlipped.toggle()
                }
            }
    }
    
    //카드의 뒷부분 - 장소의 위치 정보, 장소명, 날짜 등이 노출됨
    var cardBackView: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 315, height: 560)
            .foregroundColor(.white)
            .overlay(
                ZStack {
                    Map(bounds: MapCameraBounds(minimumDistance: 600)) {
                        Marker(space.comment, coordinate: CLLocationCoordinate2D(latitude: space.latitude, longitude: space.longitude))
                            .tint(colorScheme == .dark ? .white : .black)
                    }
                    .frame(width: 315, height: 560)
                    .cornerRadius(19)
                    .clipped()
                    
                    VStack {
                        Label(space.comment, systemImage: "map")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 30)
                        
                        Spacer()
                        
                        HStack {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                                .padding()
                                .opacity(0.4)
                            
                            Spacer()
                            
                            Text(space.date)
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                                .padding()
                        }
                        .padding(.bottom, 20)
                    }
                }
            )
            .onTapGesture {
                withAnimation(Animation.linear(duration: 0.8)) {
                    cardFlipped.toggle()
                }
            }
    }
}
