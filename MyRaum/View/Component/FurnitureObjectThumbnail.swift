//
//  FurnitureObjectThumbnail.swift
//  MyRaum
//
//  Created by Yune Cho on 11/15/26.
//

import SwiftUI

//가구의 3D 모양을 렌더링한 미리보기 이미지 - 이미지를 만드는 동안이나 만들지 못하면 SF Symbol을 보여줌
struct FurnitureObjectThumbnail: View {
    @Environment(\.displayScale) private var displayScale

    let object: FurnitureObject
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                Image(systemName: object.symbol)
                    .font(.system(size: size * 0.32, weight: .semibold))
                    .foregroundStyle(Color.gray)
            }
        }
        .frame(width: size, height: size)
        .task(id: object.id) {
            let rendered = await FurnitureThumbnailRenderer.shared.thumbnail(for: object, pointSize: size, scale: displayScale)
            withAnimation(.easeOut(duration: 0.2)) {
                image = rendered
            }
        }
    }
}
