//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//보관함 목록에서 보여지는 간략한 정보를 담은 공간 카드 뷰
//신규 카드와 같은 썸네일 형식 (배경 + 가운데 모델 + 모델 위 장소명)
struct MySpaceCellView: View {
    let space: SpaceData

    var body: some View {
        SpaceThumbnailView(space: space, width: 153)
            .overlay {
                RoundedRectangle(cornerRadius: StoryLayout.cornerRadius)
                    .stroke(Color.gray, lineWidth: 2)
            }
    }
}
