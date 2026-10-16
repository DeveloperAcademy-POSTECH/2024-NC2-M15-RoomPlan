//
//  LegacySpacesView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData

//이전 버전에서 이미지로 저장된 공간 카드들을 보여주는 화면
//길게 누르면 카드 메뉴, 선택 버튼을 누르면 여러 카드를 선택해서 삭제할 수 있음
struct LegacySpacesView: View {
    @Environment(\.modelContext) var modelContext

    @Query var spaceData: [SpaceData]

    @State private var selectedSpace: SpaceData? = nil
    @State private var spaceToDelete: SpaceData? = nil
    @State private var isSelecting: Bool = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var showBulkDeleteConfirmation: Bool = false
    @State private var showSavedAlert: Bool = false

    private let columns = [
        GridItem(),
        GridItem()
    ]

    var body: some View {
        //저장된 데이터가 없으면 저장된 공간이 없다고 노출되고, 저장된 데이터가 있을 경우 LazyVGrid 방식으로 장소 카드들을 보여줌
        Group {
            if spaceData.isEmpty {
                emptyView
            } else {
                spaceGridView
            }
        }
        .customNavigationBar(title: "이전 공간 카드") {
            selectButton
        }
        .toolbar(isSelecting ? .hidden : .visible, for: .tabBar)
        .toolbar {
            if isSelecting {
                selectionToolbar
            }
        }
        .sheet(item: $selectedSpace) { space in
            MySpaceDetailView(space: space)
        }
        .alert("공간 삭제", isPresented: $showDeleteConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }

            Button(role: .destructive) {
                if let space = spaceToDelete {
                    modelContext.deleteSpace(space: space)
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
                modelContext.deleteSpaces(spaceData.filter { selectedIDs.contains($0.id) })
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

private extension LegacySpacesView {
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

    var spaceGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(spaceData) { space in
                    MySpaceCellView(space: space)
                        .overlay {
                            if isSelecting {
                                CardSelectionOverlay(isSelected: selectedIDs.contains(space.id), cornerRadius: 19)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 19))
                        .onTapGesture {
                            if isSelecting {
                                toggleSelection(space.id)
                            } else {
                                selectedSpace = space
                            }
                        }
                        .contextMenu {
                            if !isSelecting {
                                menu(for: space)
                            }
                        }
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 20)
        }
        .padding(.top)
    }

    //카드를 길게 눌렀을 때 나오는 메뉴
    @ViewBuilder
    func menu(for space: SpaceData) -> some View {
        Button {
            UIImageWriteToSavedPhotosAlbum(space.renderCardImage(), nil, nil, nil)
            showSavedAlert = true
        } label: {
            Label("이미지 저장", systemImage: "photo.badge.arrow.down")
        }

        ShareLink(item: SpaceCardShareItem { space.renderCardImage() }, preview: SharePreview("공간 카드 공유")) {
            Label("공유", systemImage: "square.and.arrow.up")
        }

        Button(role: .destructive) {
            spaceToDelete = space
            showDeleteConfirmation = true
        } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    var selectButton: some View {
        Button {
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
        .disabled(spaceData.isEmpty)
    }

    //선택 모드에서 하단에 표시되는 전체 선택, 삭제 버튼
    @ToolbarContentBuilder
    var selectionToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                if selectedIDs.count == spaceData.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(spaceData.map(\.id))
                }
            } label: {
                if selectedIDs.count == spaceData.count {
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
                showBulkDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .disabled(selectedIDs.isEmpty)
        }
    }

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
        LegacySpacesView()
    }
    .modelContainer(for: SpaceData.self, inMemory: true)
}
