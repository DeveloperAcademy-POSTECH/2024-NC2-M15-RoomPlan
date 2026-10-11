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
        Group {
            switch cardFlipped {
            case true:
                cardBackView
            case false:
                cardFrontView
            }
        }
        .onTapGesture {
            withAnimation(Animation.linear(duration: 0.8)) {
                cardFlipped.toggle()
            }
        }
    }
}

private extension MySpaceCardView {
    //카드의 앞면 - 스캔된 모델, 배경이미지, 장소명, 날짜 등이 노출됨
    var cardFrontView: some View {
        SpaceCardFrontView(
            model: space.modelImage,
            background: space.backgroundImage,
            comment: space.comment,
            date: space.date
        )
    }

    //카드의 뒷부분 - 장소의 위치 정보, 장소명, 날짜 등이 노출됨
    var cardBackView: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 315, height: 560)
            .overlay(
                ZStack {
                    Map(bounds: MapCameraBounds(minimumDistance: 600)) {
                        if let coordinate = space.coordinate {
                            Marker(space.comment, coordinate: coordinate)
                                .tint(colorScheme == .dark ? .white : .black)
                        }
                    }
                    .frame(width: 315, height: 560)
                    .clipShape(RoundedRectangle(cornerRadius: 19))

                    VStack {
                        Label(space.comment, systemImage: "map")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(.top, 30)

                        Spacer()

                        SpaceCardFooter(date: space.date, dateColor: colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                    }
                }
            )
    }
}
