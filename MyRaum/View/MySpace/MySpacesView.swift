//
//  MySpacesView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI
import SwiftData

//보관함 화면 - 3D로 저장된 공간 카드 목록
//이전 버전에서 저장한 카드가 있으면 상단에 이전 카드 보관함으로 이동하는 버튼이 노출됨
struct MySpacesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SpaceRecord.createdAt, order: .reverse) private var records: [SpaceRecord]
    @Query private var legacySpaces: [SpaceData]

    @State private var selectedRecord: SpaceRecord? = nil
    @State private var recordToDelete: SpaceRecord? = nil
    @State private var showDeleteConfirmation: Bool = false

    private let columns = [
        GridItem(),
        GridItem()
    ]

    var body: some View {
        Group {
            if records.isEmpty && legacySpaces.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if !legacySpaces.isEmpty {
                            legacyLink
                        }

                        if records.isEmpty {
                            Text("저장된 공간이 없습니다.")
                                .foregroundStyle(Color.gray)
                                .padding(.top, 40)
                        } else {
                            recordGrid
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 20)
                }
                .padding(.top)
            }
        }
        .customNavigationBar(title: "보관함")
        .sheet(item: $selectedRecord) { record in
            SpaceRecordDetailView(record: record)
        }
        .alert("공간 삭제", isPresented: $showDeleteConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }

            Button(role: .destructive) {
                if let record = recordToDelete {
                    modelContext.deleteRecord(record)
                }
            } label: {
                Text("삭제")
            }
        }, message: {
            Text("이 공간을 삭제하시겠습니까?")
        })
    }
}

private extension MySpacesView {
    var emptyView: some View {
        VStack {
            Image("scanexport")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
                .padding()

            Text("저장된 공간이 없습니다.")
                .font(.title3)
                .bold()
                .padding(.bottom, 100)
        }
    }

    var legacyLink: some View {
        NavigationLink(value: AppRoute.legacySpaces) {
            HStack {
                Image(systemName: "photo.stack")

                Text("이전 공간 카드")

                Spacer()

                Text(verbatim: "\(legacySpaces.count)")
                    .foregroundStyle(Color.gray)

                Image(systemName: "chevron.right")
            }
            .bold()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            }
        }
    }

    var recordGrid: some View {
        LazyVGrid(columns: columns, spacing: 30) {
            ForEach(records) { record in
                StoryCardView(record: record, width: 153)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20 * 153 / StoryLayout.referenceWidth)
                            .stroke(Color.gray, lineWidth: 2)
                    }
                    .onTapGesture {
                        selectedRecord = record
                    }
                    .onLongPressGesture(minimumDuration: 0.3, perform: {
                        recordToDelete = record
                        showDeleteConfirmation = true
                    })
            }
        }
    }
}

#Preview {
    NavigationStack {
        MySpacesView()
    }
    .modelContainer(for: [SpaceRecord.self, SpaceData.self], inMemory: true)
}
