//
//  SpaceRecordEditorView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/16/26.
//

import SwiftUI

//저장된 공간 카드를 수정하는 화면 - 3D 모델을 불러온 뒤 꾸미기 화면을 보여줌
struct SpaceRecordEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let record: SpaceRecord

    @State private var room: ScannedRoom?
    @State private var showLoadFailedAlert: Bool = false

    var body: some View {
        Group {
            if let room {
                StoryEditorView(room: room, record: record) {
                    dismiss()
                }
            } else {
                ProgressView()
                    .tint(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .task {
            do {
                room = try await ScannedRoom.load(from: record)
            } catch {
                print("Failed to load model: \(error.localizedDescription)")
                showLoadFailedAlert = true
            }
        }
        .alert("3D 모델을 불러오지 못했습니다.", isPresented: $showLoadFailedAlert) {
            Button {
                dismiss()
            } label: {
                Text("확인")
            }
        }
    }
}
