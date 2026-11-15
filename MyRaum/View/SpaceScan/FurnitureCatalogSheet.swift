//
//  FurnitureCatalogSheet.swift
//  MyRaum
//
//  Created by Yune Cho on 10/30/26.
//

import SwiftUI

//가구 배치 편집 중에 추가할 가구를 고르는 시트
//오브젝트 탭과 같은 FurnitureLibrary의 목록을 보여주고 고른 가구의 source만 넘겨주므로
//"내 가구"(Object Capture로 스캔한 가구) 섹션도 FurnitureLibrary에 추가하면 여기에 함께 보임
struct FurnitureCatalogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (FurnitureSource) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("가구 추가")
                    .font(.headline)

                Spacer()

                Button {
                    HapticManager.tap()
                    dismiss()
                } label: {
                    Text("닫기")
                        .bold()
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(FurnitureLibrary.sections) { section in
                        self.section(title: section.title) {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(section.objects) { object in
                                    option(object) {
                                        select(object.source)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }
}

private extension FurnitureCatalogSheet {
    func section<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.gray)

            content()
        }
    }

    func option(_ object: FurnitureObject, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            VStack(spacing: 4) {
                FurnitureObjectThumbnail(object: object, size: 52)

                Text(object.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 10)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func select(_ source: FurnitureSource) {
        onSelect(source)
        dismiss()
    }
}
