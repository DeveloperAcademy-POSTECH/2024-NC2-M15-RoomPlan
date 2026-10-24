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
//길게 누르면 카드 메뉴, 선택 버튼을 누르면 여러 카드를 선택해서 삭제할 수 있음
struct MySpacesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SpaceRecord.createdAt, order: .reverse) private var records: [SpaceRecord]
    @Query private var legacySpaces: [SpaceData]

    @State private var selectedRecord: SpaceRecord? = nil
    @State private var viewerRecord: SpaceRecord? = nil
    @State private var editingRecord: SpaceRecord? = nil
    @State private var recordToDelete: SpaceRecord? = nil
    @State private var isSelecting: Bool = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var showBulkDeleteConfirmation: Bool = false
    @State private var showSavedAlert: Bool = false

    private let columns = [
        GridItem(),
        GridItem()
    ]
    private let cellWidth: CGFloat = 153

    var body: some View {
        Group {
            if records.isEmpty && legacySpaces.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if !legacySpaces.isEmpty && !isSelecting {
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
                    //스크롤된 카드가 상단 툴바 아래로 지나가도록 여백을 스크롤 영역 안쪽에 둠
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
            }
        }
        .customNavigationBar(title: "보관함", showsBackButton: false) {
            selectButton
        }
        .toolbar(isSelecting ? .hidden : .visible, for: .tabBar)
        .toolbar {
            if isSelecting {
                selectionToolbar
            }
        }
        .sheet(item: $selectedRecord) { record in
            SpaceRecordDetailView(record: record)
        }
        .fullScreenCover(item: $viewerRecord) { record in
            RoomModelViewerView(record: record)
        }
        .fullScreenCover(item: $editingRecord) { record in
            SpaceRecordEditorView(record: record)
        }
        .alert("공간 삭제", isPresented: $showDeleteConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }

            Button(role: .destructive) {
                HapticManager.notify(.success)
                if let record = recordToDelete {
                    modelContext.deleteRecord(record)
                }
            } label: {
                Text("삭제")
            }
        }, message: {
            Text("이 공간을 삭제하시겠습니까?")
        })
        .alert("공간 삭제", isPresented: $showBulkDeleteConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }

            Button(role: .destructive) {
                HapticManager.notify(.success)
                modelContext.deleteRecords(records.filter { selectedIDs.contains($0.id) })
                endSelecting()
            } label: {
                Text("삭제")
            }
        }, message: {
            Text("선택한 \(selectedIDs.count)개의 공간을 삭제하시겠습니까?")
        })
        .alert("이미지가 저장되었습니다.", isPresented: $showSavedAlert) {
            Button {
            } label: {
                Text("확인")
            }
        }
    }
}

// MARK: - Views
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
        .hapticOnTap()
    }

    var recordGrid: some View {
        LazyVGrid(columns: columns, spacing: 30) {
            ForEach(records) { record in
                recordCell(record)
            }
        }
    }

    func recordCell(_ record: SpaceRecord) -> some View {
        let cornerRadius = StoryLayout.cornerRadius

        //이전 카드와 같은 썸네일 형식으로 표시
        return SpaceThumbnailView(record: record, width: cellWidth)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray, lineWidth: 2)
            }
            .overlay {
                if isSelecting {
                    CardSelectionOverlay(isSelected: selectedIDs.contains(record.id), cornerRadius: cornerRadius)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture {
                if isSelecting {
                    HapticManager.selection()
                    toggleSelection(record.id)
                } else {
                    HapticManager.tap()
                    selectedRecord = record
                }
            }
            .contextMenu {
                if !isSelecting {
                    menu(for: record)
                }
            }
    }

    //카드를 길게 눌렀을 때 나오는 메뉴
    @ViewBuilder
    func menu(for record: SpaceRecord) -> some View {
        Button {
            viewerRecord = record
        } label: {
            Label("3D로 보기", systemImage: "rotate.3d")
        }

        Button {
            editingRecord = record
        } label: {
            Label("수정하기", systemImage: "pencil")
        }

        Button {
            if let image = record.renderCardImage() {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                HapticManager.notify(.success)
                showSavedAlert = true
            }
        } label: {
            Label("이미지 저장", systemImage: "photo.badge.arrow.down")
        }

        ShareLink(item: SpaceCardShareItem { record.renderCardImage() }, preview: SharePreview("공간 카드 공유")) {
            Label("공유", systemImage: "square.and.arrow.up")
        }

        Button(role: .destructive) {
            recordToDelete = record
            showDeleteConfirmation = true
        } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    var selectButton: some View {
        Button {
            HapticManager.tap()
            if isSelecting {
                endSelecting()
            } else {
                isSelecting = true
            }
        } label: {
            if isSelecting {
                Text("완료")
                    .bold()
            } else {
                Text("선택")
            }
        }
        .disabled(records.isEmpty)
    }

    //선택 모드에서 하단에 표시되는 전체 선택, 삭제 버튼
    @ToolbarContentBuilder
    var selectionToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                HapticManager.selection()
                if selectedIDs.count == records.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(records.map(\.id))
                }
            } label: {
                if selectedIDs.count == records.count {
                    Text("선택 해제")
                } else {
                    Text("전체 선택")
                }
            }
        }

        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }

        ToolbarItem(placement: .bottomBar) {
            Button(role: .destructive) {
                HapticManager.tap()
                showBulkDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .disabled(selectedIDs.isEmpty)
        }
    }
}

// MARK: - Selection
private extension MySpacesView {
    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func endSelecting() {
        isSelecting = false
        selectedIDs.removeAll()
    }
}

#Preview {
    NavigationStack {
        MySpacesView()
    }
    .modelContainer(for: [SpaceRecord.self, SpaceData.self], inMemory: true)
}
