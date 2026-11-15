//
//  FurnitureObjectDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 11/15/26.
//

import SwiftUI

//가구 하나를 3D로 돌려볼 수 있는 화면
//한 손가락: 회전, 두 손가락: 이동, 핀치: 확대/축소 (RoomSceneView와 같은 조작)
struct FurnitureObjectDetailView: View {
    let object: FurnitureObject

    @State private var roomScene: RoomScene?
    @State private var camera = RoomSceneCamera()

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()

            //가구가 정보 카드에 가려지지 않도록 3D 화면은 카드 위의 남은 공간을 채움
            VStack(spacing: 12) {
                ZStack {
                    if let roomScene {
                        RoomSceneView(roomScene: roomScene, camera: camera)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if roomScene != nil {
                    //가구를 옮기거나 확대/축소해서 화면 가운데에서 벗어나면 안내 문구 대신 가운데로 버튼을 보여줌
                    if camera.isOffCenter {
                        recenterButton
                    } else {
                        Text("드래그해서 가구를 돌려보세요.")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                            .allowsHitTesting(false)
                    }
                }

                infoCard
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
        .customNavigationBar(title: object.name)
        .toolbar(.hidden, for: .tabBar)
        .task {
            roomScene = FurnitureObjectScene.make(for: object)
        }
    }
}

private extension FurnitureObjectDetailView {
    var recenterButton: some View {
        Button {
            HapticManager.tap()
            camera.recenter()
        } label: {
            Label("가운데로", systemImage: "scope")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(.systemBackground)))
        }
    }

    //가구 이름, 종류와 공간에 추가할 때의 기본 크기
    var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(object.name)
                    .font(.title3.bold())

                if let category = object.category {
                    Label(category.name, systemImage: category.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.gray.opacity(0.12)))
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                dimension("가로", value: object.size.x)
                dimension("높이", value: object.size.y)
                dimension("깊이", value: object.size.z)
            }

            Text("공간 편집에서 이 크기로 추가됩니다.")
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
    }

    func dimension(_ title: LocalizedStringKey, value: Float) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gray)

            Text(verbatim: "\(Int((value * 100).rounded())) cm")
                .font(.headline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        if let object = FurnitureLibrary.object(for: .catalog("sofa.lShaped")) {
            FurnitureObjectDetailView(object: object)
        }
    }
}
