//
//  FurnitureObjectsView.swift
//  MyRaum
//
//  Created by Yune Cho on 11/15/26.
//

import SwiftUI

//오브젝트 탭 - 공간 편집 화면에서 추가할 수 있는 가구 목록
//가구를 누르면 3D로 돌려볼 수 있는 화면으로 이동
//목록은 FurnitureLibrary에서 가져오므로 스캔한 내 가구를 추가하면 같은 화면에 섹션으로 함께 보임
struct FurnitureObjectsView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("공간 편집에서 추가할 수 있는 가구입니다.\n가구를 눌러 3D로 살펴보세요.")
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)

                ForEach(FurnitureLibrary.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.objects) { object in
                                NavigationLink(value: AppRoute.furnitureObject(object.source)) {
                                    cell(object)
                                }
                                .buttonStyle(.plain)
                                .hapticOnTap()
                            }
                        }
                    }
                }
            }
            //스크롤된 내용이 상단 툴바 아래로 지나가도록 여백을 스크롤 영역 안쪽에 둠
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .customNavigationBar(title: "오브젝트", showsBackButton: false)
    }
}

private extension FurnitureObjectsView {
    func cell(_ object: FurnitureObject) -> some View {
        VStack(spacing: 6) {
            FurnitureObjectThumbnail(object: object, size: 84)

            Text(object.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.12)))
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        FurnitureObjectsView()
    }
}
