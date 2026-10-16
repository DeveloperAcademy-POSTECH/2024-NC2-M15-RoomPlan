//
//  StoryCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI

//저장된 공간 카드 - 배경, 3D 모델 이미지, 스토리 요소들을 합쳐서 보여줌
//보관함 목록, 상세 화면, 이미지 저장/공유에서 같은 뷰를 크기만 바꿔서 사용
struct StoryCardView: View {
    let background: UIImage?
    let backgroundPreset: Int
    let thumbnail: UIImage?
    let elements: [StoryElement]
    let furniture: [FurnitureCategory]
    let width: CGFloat
    var cornerRadius: CGFloat = StoryLayout.cornerRadius

    var body: some View {
        let size = StoryLayout.size(fittingWidth: width)
        let unit = width / StoryLayout.referenceWidth

        ZStack {
            StoryBackgroundView(image: background, preset: backgroundPreset)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            }

            ForEach(elements) { element in
                StoryElementView(element: element, furniture: furniture, unit: unit)
                    .scaleEffect(element.scale)
                    .position(x: element.position.x * size.width, y: element.position.y * size.height)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension StoryCardView {
    init(record: SpaceRecord, width: CGFloat, cornerRadius: CGFloat = StoryLayout.cornerRadius) {
        self.init(
            background: record.backgroundImage,
            backgroundPreset: record.backgroundPreset,
            thumbnail: record.thumbnailImage,
            elements: record.elements,
            furniture: record.furniture,
            width: width,
            cornerRadius: cornerRadius
        )
    }
}

//카드 배경 - 사진을 선택하지 않았으면 그라데이션
struct StoryBackgroundView: View {
    let image: UIImage?
    let preset: Int

    var body: some View {
        if let image {
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .overlay(Color.black.opacity(0.3))
                .clipped()
        } else {
            StoryBackgroundPreset.gradient(at: preset)
        }
    }
}

//카드 위에 올라가는 요소 하나를 그리는 뷰
//unit은 카드의 기준 너비(360) 대비 실제 너비의 비율
struct StoryElementView: View {
    let element: StoryElement
    let furniture: [FurnitureCategory]
    let unit: CGFloat

    var body: some View {
        switch element.kind {
        case .text:
            Text(element.text)
                .font(.system(size: 28 * unit, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
                .shadow(color: .black.opacity(0.35), radius: 4 * unit)
                .frame(maxWidth: 300 * unit)
                .fixedSize(horizontal: false, vertical: true)

        case .location:
            HStack(spacing: 6 * unit) {
                Image("locationpin")
                    .resizable()
                    .frame(width: 17 * unit, height: 21 * unit)

                Text(element.text)
                    .font(.system(size: 18 * unit, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14 * unit)
            .padding(.vertical, 8 * unit)
            .background(Capsule().fill(Color.black.opacity(0.35)))

        case .date:
            Text(element.text)
                .font(.system(size: 23 * unit, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.35), radius: 4 * unit)

        case .furniture:
            //가구 종류는 언어와 상관없이 보이도록 아이콘 + 개수로 표시
            HStack(spacing: 12 * unit) {
                ForEach(FurnitureCount.summarize(furniture).prefix(5)) { item in
                    HStack(spacing: 4 * unit) {
                        Image(systemName: item.category.symbol)
                        Text(verbatim: "\(item.count)")
                    }
                }
            }
            .font(.system(size: 15 * unit, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14 * unit)
            .padding(.vertical, 8 * unit)
            .background(Capsule().fill(Color.black.opacity(0.35)))
        }
    }
}

#Preview {
    StoryCardView(
        background: nil,
        backgroundPreset: 2,
        thumbnail: nil,
        elements: [
            StoryElement(kind: .location, text: "포항", position: CGPoint(x: 0.5, y: 0.1)),
            StoryElement(kind: .text, text: "우리 집 거실", position: CGPoint(x: 0.5, y: 0.45)),
            StoryElement(kind: .furniture, text: "", position: CGPoint(x: 0.5, y: 0.82)),
            StoryElement(kind: .date, text: "2026.10.15", position: CGPoint(x: 0.78, y: 0.93))
        ],
        furniture: [.sofa, .chair, .chair, .table, .television],
        width: 315
    )
}
