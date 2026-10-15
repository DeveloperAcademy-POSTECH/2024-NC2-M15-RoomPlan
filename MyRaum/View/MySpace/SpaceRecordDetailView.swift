//
//  SpaceRecordDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI

//저장된 공간 카드를 크게 보고, 3D 모델 보기 / 이미지 저장 / 공유가 가능한 뷰
struct SpaceRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let record: SpaceRecord

    @State private var cardImage: UIImage = UIImage()
    @State private var showModelViewer: Bool = false
    @State private var showSavedAlert: Bool = false

    var body: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "x.circle")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .bold()
                }
                .padding()
            }

            StoryCardView(record: record, width: 315)
                .overlay {
                    RoundedRectangle(cornerRadius: 20 * 315 / StoryLayout.referenceWidth)
                        .stroke(Color.gray, lineWidth: 2)
                }
                .onTapGesture {
                    showModelViewer = true
                }

            Spacer()

            VStack(spacing: 12) {
                LabelButtonRoundedRectangle(text: "3D로 보기", image: "rotate.3d") {
                    showModelViewer = true
                }

                HStack(spacing: 16) {
                    LabelButtonRoundedRectangle(text: "이미지 저장", image: "photo.badge.arrow.down") {
                        UIImageWriteToSavedPhotosAlbum(cardImage, nil, nil, nil)
                        showSavedAlert = true
                    }

                    ShareLink(item: Image(uiImage: cardImage), preview: SharePreview("공간 카드 공유", icon: "AppIcon")) {
                        RoundedRectangleButtonLabel(text: "공유", systemImage: "square.and.arrow.up", height: 40, cornerRadius: 8)
                    }
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .onAppear {
            //저장 및 공유에는 카드를 이미지로 변환해서 사용
            let renderer = ImageRenderer(content: StoryCardView(record: record, width: StoryLayout.referenceWidth))
            renderer.scale = 3
            cardImage = renderer.uiImage ?? UIImage()
        }
        .alert("이미지가 저장되었습니다.", isPresented: $showSavedAlert) {
            Button {
            } label: {
                Text("확인")
            }
        }
        .fullScreenCover(isPresented: $showModelViewer) {
            RoomModelViewerView(record: record)
        }
    }
}
