//
//  MySpaceCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import SwiftUI

//MySpaceDetailView에 보이는 카드 부분을 그린 뷰
struct MySpaceCardView: View {
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
        SpaceCardMapView(title: space.comment, coordinate: space.coordinate, date: space.date)
    }
}
