//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//보관함 목록에서 보여지는 간략한 정보를 담은 공간 카드 뷰
struct MySpaceCellView: View {
    let space: SpaceData

    var body: some View {
        RoundedRectangle(cornerRadius: 19)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 153, height: 272)
            .overlay(
                ZStack {
                    if let background = space.backgroundImage {
                        SpaceCardBackground(image: background, width: 153, height: 272)
                    }

                    SpaceLocationLabel(comment: space.comment)
                }
            )
    }
}
