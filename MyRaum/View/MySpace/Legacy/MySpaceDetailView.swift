//
//  MySpaceDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//저장된 공간의 상세 정보를 확인하고 이미지 저장 및 공유가 가능한 뷰
struct MySpaceDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let space: SpaceData
    
    @State private var card: UIImage = UIImage()
    @State private var showShare: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var cardFlipped: Bool = false
    
    var body: some View {
        VStack {
            SpaceCardSheetHeader(cardFlipped: $cardFlipped)
            
            MySpaceCardView(space: space, cardFlipped: $cardFlipped)
                .onAppear(perform: {
                    //저장 및 공유에는 카드 앞면을 이미지로 변환해서 사용
                    card = SpaceCardFrontView(
                        model: space.modelImage,
                        background: space.backgroundImage,
                        comment: space.comment,
                        date: space.date
                    ).snapshot()
                })
            
            Spacer()
            
            HStack(spacing: 16) {
                LabelButtonRoundedRectangle(text: "이미지 저장", image: "photo.badge.arrow.down", color: .adaptive(colorScheme)) {
                    UIImageWriteToSavedPhotosAlbum(card, nil, nil, nil)
                    showSavedAlert = true
                }
                .frame(width: 150)
                .alert("이미지가 저장되었습니다.", isPresented: $showSavedAlert) {
                    Button {
                    } label: {
                        Text("확인")
                    }
                }
                
                ShareLink(item: Image(uiImage: card), preview: SharePreview("공간 카드 공유", icon: "AppIcon")) {
                    RoundedRectangleButtonLabel(text: "공유", systemImage: "square.and.arrow.up", height: 40, cornerRadius: 8, color: .adaptive(colorScheme))
                }
                .hapticOnTap()
                .frame(width: 150)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}
