//
//  RoomModelViewerView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI

//저장된 3D 공간을 돌려가며 볼 수 있는 화면
struct RoomModelViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let record: SpaceRecord

    @State private var roomScene: RoomScene?
    @State private var modelURL: URL?
    @State private var loadFailed: Bool = false

    var body: some View {
        ZStack {
            //하얀 모형이 잘 보이도록 밝은 회색 배경
            Color(red: 0.95, green: 0.95, blue: 0.96)
                .ignoresSafeArea()

            if let roomScene {
                RoomSceneView(roomScene: roomScene)
                    .ignoresSafeArea()
            } else if loadFailed {
                Text("3D 모델을 불러오지 못했습니다.")
                    .foregroundStyle(Color.gray)
            } else {
                ProgressView()
            }

            VStack {
                topBar

                Spacer()

                if roomScene != nil {
                    Text("드래그해서 공간을 돌려보세요.")
                        .font(.footnote)
                        .foregroundStyle(Color.gray)
                        .allowsHitTesting(false)
                }

                furnitureList
            }
            .padding()
        }
        .environment(\.colorScheme, .light)
        .task {
            await loadModel()
        }
    }
}

private extension RoomModelViewerView {
    var topBar: some View {
        HStack {
            Button {
                HapticManager.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.06)))
            }
            .accessibilityLabel(Text("닫기"))

            Spacer()

            VStack(spacing: 2) {
                Text(record.title)
                    .bold()
                    .lineLimit(1)

                Text(record.createdAt.cardDateString)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }

            Spacer()

            //USDZ 파일로 공유하면 받는 사람도 AR Quick Look으로 3D 모델을 볼 수 있음
            if let modelURL {
                ShareLink(item: modelURL, preview: SharePreview("3D 모델", icon: "AppIcon")) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.06)))
                }
                .hapticOnTap()
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
        .foregroundStyle(Color.black)
    }

    //RoomPlan이 인식한 가구 목록
    var furnitureList: some View {
        let items = FurnitureCount.summarize(record.furniture)

        return Group {
            if items.isEmpty {
                Text("인식된 가구가 없습니다.")
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            HStack(spacing: 6) {
                                Image(systemName: item.category.symbol)

                                Text(item.category.name)

                                Text(verbatim: "\(item.count)")
                                    .foregroundStyle(Color.gray)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white))
                        }
                    }
                }
            }
        }
    }

    //카드를 만들 때 맞춘 각도로 시작
    func loadModel() async {
        do {
            let room = try await ScannedRoom.load(from: record)
            modelURL = room.modelURL
            roomScene = room.roomScene
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
            loadFailed = true
        }
    }
}
