//
//  SpaceCardFrontView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/11/26.
//

import SwiftUI

//공간 카드의 앞면 - 스캔된 모델, 배경이미지, 장소명, 날짜 등이 노출됨
//카드를 만드는 과정(RoomPlanView)과 보관함(MySpaceCardView)에서 함께 사용
struct SpaceCardFrontView: View {
    let model: UIImage?
    let background: UIImage?
    let comment: String
    let date: String?

    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .foregroundStyle(Color.white)
            .frame(width: 315, height: 560)
            .overlay {
                ZStack {
                    if let background {
                        SpaceCardBackground(image: background, width: 315, height: 560)
                    }

                    VStack {
                        HStack {
                            if !comment.isEmpty {
                                SpaceLocationLabel(comment: comment)
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

                        if let date {
                            SpaceCardFooter(date: date, dateColor: Color.white.opacity(0.8))
                        } else {
                            Color.clear
                                .frame(height: 30)
                                .padding(.bottom, 20)
                        }
                    }

                    RoundedRectangle(cornerRadius: 19)
                        .stroke(Color.gray, lineWidth: 2)
                }
            }
    }
}

//어둡게 처리된 카드 배경 이미지
struct SpaceCardBackground: View {
    let image: UIImage
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .overlay(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 19))
    }
}

//핀 아이콘 + 장소명
struct SpaceLocationLabel: View {
    let comment: String

    var body: some View {
        Label {
            Text(comment)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
        } icon: {
            Image("locationpin")
                .resizable()
                .frame(width: 17, height: 21)
        }
    }
}

//카드 하단의 로고 + 날짜
struct SpaceCardFooter: View {
    let date: String
    let dateColor: Color

    var body: some View {
        HStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
                .padding()
                .opacity(0.4)

            Spacer()

            Text(date)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(dateColor)
                .padding()
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    SpaceCardFrontView(model: nil, background: nil, comment: "포항", date: "2026.10.11")
}
