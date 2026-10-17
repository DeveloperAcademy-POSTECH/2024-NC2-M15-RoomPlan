//
//  StoryBackgroundPicker.swift
//  MyRaum
//
//  Created by Yune Cho on 10/16/26.
//

import SwiftUI
import PhotosUI

//공간 카드의 배경 설정 - 사진과 색상 중 하나를 선택
struct StoryBackgroundPicker: View {
    @Environment(\.dismiss) private var dismiss

    let draft: StoryDraft
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("배경 설정")
                    .font(.headline)

                Spacer()

                Button {
                    HapticManager.tap()
                    dismiss()
                } label: {
                    Text("완료")
                        .bold()
                }
            }

            section(title: "사진") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    photoOption
                }
                .buttonStyle(.plain)
                .hapticOnTap()
            }

            section(title: "색상") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(StoryBackgroundPreset.gradients.indices, id: \.self) { index in
                            colorOption(index)
                        }
                    }
                    .padding(4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.height(300)])
        //시트가 열려 있어도 위쪽의 카드에서 배경이 바뀌는 것을 볼 수 있도록 어둡게 처리하지 않음
        .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
    }
}

private extension StoryBackgroundPicker {
    func section<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.gray)

            content()
        }
    }

    //선택된 사진이 있으면 미리보기와 체크 표시
    var photoOption: some View {
        HStack(spacing: 12) {
            Group {
                if let background = draft.background {
                    Image(uiImage: background)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if draft.background == nil {
                Text("사진 선택")
            } else {
                Text("사진 변경")
            }

            Spacer()

            if draft.background != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
            }
        }
        .bold()
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
        .contentShape(Rectangle())
    }

    //사진이 없을 때만 선택된 색상을 표시
    func colorOption(_ index: Int) -> some View {
        let isSelected = draft.background == nil && draft.backgroundPreset == index

        return Circle()
            .fill(StoryBackgroundPreset.gradient(at: index))
            .frame(width: 44, height: 44)
            .overlay {
                Circle()
                    .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    .padding(-5)
            }
            .padding(5)
            .contentShape(Circle())
            .onTapGesture {
                HapticManager.selection()
                draft.setBackgroundPreset(index)
            }
    }
}
