//
//  FurnitureCatalogSheet.swift
//  MyRaum
//
//  Created by Yune Cho on 10/30/26.
//

import SwiftUI

//가구 배치 편집 중에 추가할 가구를 고르는 시트
//고른 가구의 source만 넘겨주므로 3단계에서 "내 가구"(Object Capture로 스캔한 가구) 섹션을 같은 방식으로 붙일 수 있음
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
                    section(title: "기본 가구") {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(FurnitureCatalog.categories, id: \.self) { category in
                                option(category.symbol, name: category.name) {
                                    select(.catalog(category))
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

    func option(_ systemImage: String, name: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(height: 28)

                Text(name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
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
