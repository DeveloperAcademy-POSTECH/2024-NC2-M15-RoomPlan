//
//  MySpacesView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData

//보관함 화면 — 2.0에서 스캔한 3D 카드만 보여준다
struct MySpacesView: View {
    @Environment(AppContainer.self) private var container
    
    @Query private var spaceData: [SpaceData]
    //"이전 카드 보기" 진입점은 레거시 카드가 있을 때만 노출한다
    @Query private var legacySpaceData: [SpaceData]
    
    //드로어를 닫는 동작. NavigationStack의 루트라 화면 닫기를 주입받는다
    let onClose: () -> Void
    
    @State private var selectedSpace: SpaceData? = nil
    @State private var selectedStructure: SpaceGroup? = nil
    @State private var spaceToDelete: SpaceData? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        
        let usdzKind = SpaceStorageKind.usdz.rawValue
        let legacyKind = SpaceStorageKind.legacyImage.rawValue
        
        _spaceData = Query(
            filter: #Predicate<SpaceData> { $0.storageKind == usdzKind },
            sort: \.createdAt,
            order: .reverse
        )
        _legacySpaceData = Query(
            filter: #Predicate<SpaceData> { $0.storageKind == legacyKind },
            sort: \.createdAt,
            order: .reverse
        )
    }
    
    var body: some View {
        //저장된 데이터가 없으면 저장된 공간이 없다고 노출되고, 저장된 데이터가 있을 경우 LazyVGrid 방식으로 장소 카드들을 보여줌
        Group {
            if spaceData.isEmpty {
                emptyView
            } else {
                spaceGrid
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .bold()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("보관함")
                    .bold()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink {
                        SpaceMapView()
                    } label: {
                        Label("지도에서 보기", systemImage: "map")
                    }
                    
                    //레거시 카드가 있을 때만 이전 카드 진입점을 노출한다
                    if legacySpaceData.isEmpty == false {
                        NavigationLink {
                            LegacyArchiveView()
                        } label: {
                            Label("이전 카드 보기", systemImage: "clock.arrow.circlepath")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .bold()
                }
            }
        }
        .sheet(item: $selectedSpace) { space in
            MySpaceDetailView(space: space)
        }
        .sheet(item: $selectedStructure) { group in
            StructureDetailView(group: group)
        }
        .alert("공간 삭제", isPresented: $showDeleteConfirmation, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }
            
            Button(role: .destructive) {
                if let space = spaceToDelete {
                    container.spaceRepository.delete(space)
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
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //구조에 속한 방들은 한 칸으로 묶어 보여준다 (8.1)
    var groups: [SpaceGroup] {
        SpaceGrouping.group(spaceData)
    }
    
    var spaceGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(groups) { group in
                    if let representative = group.representative {
                        cell(for: group, representative: representative)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 20)
        }
        .padding(.top)
    }
    
    func cell(for group: SpaceGroup, representative: SpaceData) -> some View {
        SpaceCellView(space: representative)
            //묶인 구조는 방 개수를 배지로 표시한다
            .overlay(alignment: .topTrailing) {
                if group.isStructure {
                    Label("\(group.roomCount)", systemImage: "square.stack.3d.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule().foregroundStyle(Color.black.opacity(0.6))
                        }
                        .padding(8)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel(for: group, representative: representative))
            .onTapGesture {
                if group.isStructure {
                    selectedStructure = group
                } else {
                    selectedSpace = representative
                }
            }
            .onLongPressGesture(minimumDuration: 0.3, perform: {
                //구조는 방 단위로 지워야 하므로 상세에서 처리한다
                guard group.isStructure == false else { return }
                spaceToDelete = representative
                showDeleteConfirmation = true
            })
    }
    
    //VoiceOver로 카드 정보를 읽어 준다 (8.5)
    func accessibilityLabel(for group: SpaceGroup, representative: SpaceData) -> Text {
        let name = representative.comment.isEmpty ? String(localized: "이름 없는 방") : representative.comment
        
        if group.isStructure {
            return Text("\(name), \(group.roomCount)개의 방")
        }
        return Text("\(name), \(representative.displayDate)")
    }
}
