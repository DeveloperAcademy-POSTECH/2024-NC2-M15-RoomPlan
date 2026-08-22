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
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    
    @Query private var spaceData: [SpaceData]
    //"이전 카드 보기" 진입점은 레거시 카드가 있을 때만 노출한다
    @Query private var legacySpaceData: [SpaceData]
    
    @State private var selectedSpace: SpaceData? = nil
    @State private var spaceToDelete: SpaceData? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    init() {
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
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .bold()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("보관함")
                    .bold()
            }
            
            if legacySpaceData.isEmpty == false {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        LegacyArchiveView()
                    } label: {
                        Text("이전 카드 보기")
                    }
                }
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
    
    var spaceGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(spaceData) { space in
                    SpaceCellView(space: space)
                        .onTapGesture {
                            selectedSpace = space
                        }
                        .onLongPressGesture(minimumDuration: 0.3, perform: {
                            spaceToDelete = space
                            showDeleteConfirmation = true
                        })
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 20)
        }
        .padding(.top)
    }
}
