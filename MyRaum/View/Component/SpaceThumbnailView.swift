//
//  SpaceThumbnailView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//보관함, 지도에서 보여지는 공간 카드 썸네일
//신규 카드와 이전 카드가 같은 모양으로 보이도록 배경 + 가운데 모델 + 모델 위 장소명만 표시
//title이 nil이면 장소명 없이 배경과 모델만 표시 (지도)
struct SpaceThumbnailView<Background: View>: View {
    let model: UIImage?
    let title: String?
    let width: CGFloat
    var cornerRadius: CGFloat = StoryLayout.cornerRadius
    @ViewBuilder let background: () -> Background

    var body: some View {
        let height = width / StoryLayout.aspectRatio

        ZStack {
            background()

            if let model {
                Image(uiImage: model)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: width * 0.8, maxHeight: height * 0.45)
                    //모델은 항상 가운데에 두고 장소명은 모델 바로 위에 붙임
                    .overlay(alignment: .top) {
                        titleLabel
                            .alignmentGuide(.top) { $0[.bottom] + 12 }
                    }
            } else {
                titleLabel
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var titleLabel: some View {
        if let title, !title.isEmpty {
            SpaceLocationLabel(comment: title)
                .lineLimit(1)
                .frame(width: width - 20)
        }
    }
}

extension SpaceThumbnailView where Background == StoryBackgroundView {
    init(record: SpaceRecord, width: CGFloat, showsTitle: Bool = true, cornerRadius: CGFloat = StoryLayout.cornerRadius) {
        self.init(
            model: record.thumbnailImage?.trimmingTransparentPixels(cacheKey: "record-\(record.id)-\(record.thumbnail.count)"),
            title: showsTitle ? record.title : nil,
            width: width,
            cornerRadius: cornerRadius
        ) {
            StoryBackgroundView(image: record.backgroundImage, preset: record.backgroundPreset)
        }
    }
}

extension SpaceThumbnailView where Background == LegacyThumbnailBackground {
    init(space: SpaceData, width: CGFloat, showsTitle: Bool = true, cornerRadius: CGFloat = StoryLayout.cornerRadius) {
        self.init(
            model: space.modelImage?.trimmingTransparentPixels(cacheKey: "legacy-\(space.id)-\(space.model.count)"),
            title: showsTitle ? space.comment : nil,
            width: width,
            cornerRadius: cornerRadius
        ) {
            LegacyThumbnailBackground(image: space.backgroundImage)
        }
    }
}

//이전 카드의 배경 - 배경 이미지가 없으면 회색
struct LegacyThumbnailBackground: View {
    let image: UIImage?

    var body: some View {
        if let image {
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .overlay(Color.black.opacity(0.4))
                .clipped()
        } else {
            Color.gray
        }
    }
}
