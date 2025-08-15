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
                    Image(uiImage: UIImage(data: space.background)!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 315, height: 560)
                        .overlay(Color.black.opacity(0.4))
                        .cornerRadius(19)
                        .clipped()
                    
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
                        
                        Image(uiImage: UIImage(data: space.model)!)
                            .resizable()
                            .scaledToFit()
                        
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
