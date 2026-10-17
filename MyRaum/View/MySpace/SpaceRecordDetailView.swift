//
//  SpaceRecordDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI

//저장된 공간 카드를 크게 보고, 3D 모델 보기 / 수정 / 이미지 저장 / 공유가 가능한 뷰
struct SpaceRecordDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let record: SpaceRecord

    @State private var cardImage: UIImage = UIImage()
    @State private var showModelViewer: Bool = false
    @State private var showEditor: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var cardFlipped: Bool = false

    var body: some View {
        VStack {
            SpaceCardSheetHeader(cardFlipped: $cardFlipped)

            card

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    LabelButtonRoundedRectangle(text: "수정하기", image: "pencil", color: buttonColor) {
                        showEditor = true
                    }

                    LabelButtonRoundedRectangle(text: "3D로 보기", image: "rotate.3d", color: buttonColor) {
                        showModelViewer = true
                    }
                }

                HStack(spacing: 16) {
                    LabelButtonRoundedRectangle(text: "이미지 저장", image: "photo.badge.arrow.down", color: buttonColor) {
                        UIImageWriteToSavedPhotosAlbum(cardImage, nil, nil, nil)
                        showSavedAlert = true
                    }

                    ShareLink(item: Image(uiImage: cardImage), preview: SharePreview("공간 카드 공유", icon: "AppIcon")) {
                        RoundedRectangleButtonLabel(text: "공유", systemImage: "square.and.arrow.up", height: 40, cornerRadius: 8, color: buttonColor)
                    }
                    .hapticOnTap()
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .onAppear {
            renderCardImage()
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
        //수정이 끝나면 저장, 공유용 이미지도 새로 만듦
        .fullScreenCover(isPresented: $showEditor, onDismiss: renderCardImage) {
            SpaceRecordEditorView(record: record)
        }
    }
}

private extension SpaceRecordDetailView {
    //라이트 모드에서는 시트 배경과 같은 테두리 버튼
    var buttonColor: ButtonColor {
        .adaptive(colorScheme)
    }

    //이전 카드처럼 카드를 탭하거나 상단 메뉴로 앞면(카드)과 뒷면(지도)을 전환
    //3D 모델은 '3D로 보기' 버튼으로만 열림
    var card: some View {
        Group {
            if cardFlipped {
                SpaceCardMapView(title: record.title, coordinate: record.coordinate, date: record.createdAt.cardDateString)
            } else {
                StoryCardView(record: record, width: 315)
                    .overlay {
                        RoundedRectangle(cornerRadius: StoryLayout.cornerRadius)
                            .stroke(Color.gray, lineWidth: 2)
                    }
            }
        }
        .onTapGesture {
            withAnimation(Animation.linear(duration: 0.8)) {
                cardFlipped.toggle()
            }
        }
    }

    //저장 및 공유에는 카드를 이미지로 변환해서 사용
    func renderCardImage() {
        let renderer = ImageRenderer(content: StoryCardView(record: record, width: StoryLayout.referenceWidth))
        renderer.scale = 3
        cardImage = renderer.uiImage ?? UIImage()
    }
}
