//
//  SpaceCardImage.swift
//  MyRaum
//
//  Created by Yune Cho on 10/16/26.
//

import SwiftUI
import UniformTypeIdentifiers

//공간 카드를 이미지로 저장하거나 공유하기 위해 렌더링
extension SpaceRecord {
    @MainActor
    func renderCardImage() -> UIImage? {
        let renderer = ImageRenderer(content: StoryCardView(record: self, width: StoryLayout.referenceWidth))
        renderer.scale = 3
        return renderer.uiImage
    }
}

extension SpaceData {
    @MainActor
    func renderCardImage() -> UIImage {
        SpaceCardFrontView(model: modelImage, background: backgroundImage, comment: comment, date: date).snapshot()
    }
}

//공유할 때 카드 이미지를 만드는 항목
//보관함 목록에서 카드마다 미리 이미지를 만들지 않도록 공유가 실행될 때 렌더링함
struct SpaceCardShareItem: Transferable {
    let render: @MainActor () -> UIImage?

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            await item.render()?.pngData() ?? Data()
        }
    }
}

//다중 선택 모드에서 카드 위에 표시되는 선택 상태
struct CardSelectionOverlay: View {
    let isSelected: Bool
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.black.opacity(isSelected ? 0.3 : 0))
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(Color.white, isSelected ? Color.blue : Color.black.opacity(0.3))
                    .padding(8)
            }
            .allowsHitTesting(false)
    }
}
