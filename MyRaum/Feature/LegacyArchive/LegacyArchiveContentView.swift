//
//  LegacyArchiveContentView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import SwiftData

//레거시 카드 목록 본문
//보관함에서 밀려 들어오는 경우와 레거시 전용 모드가 함께 사용한다
struct LegacyArchiveContentView: View {
    @Environment(AppContainer.self) private var container
    
    @Query private var legacySpaceData: [SpaceData]
    
    @State private var selectedSpace: SpaceData? = nil
    @State private var spaceToDelete: SpaceData? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    init() {
        let legacyKind = SpaceStorageKind.legacyImage.rawValue
        
        _legacySpaceData = Query(
            filter: #Predicate<SpaceData> { $0.storageKind == legacyKind },
            sort: \.createdAt,
            order: .reverse
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            //기기를 바꾸면 복원되지 않는다는 점을 안내한다 (D-06)
            noticeBanner
            
            if legacySpaceData.isEmpty {
                Spacer()
                
                Text("이전 카드가 없습니다.")
                    .font(.title3)
                    .bold()
                
                Spacer()
            } else {
                legacyGrid
            }
        }
        .sheet(item: $selectedSpace) { space in
            LegacyDetailView(space: space)
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

private extension LegacyArchiveContentView {
    var noticeBanner: some View {
        Label {
            Text("이전 카드는 이 기기에만 저장되어 있어 기기를 바꾸면 복원되지 않습니다.")
                .font(.caption)
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: "info.circle")
                .font(.caption)
        }
        .foregroundStyle(Color.gray)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    var legacyGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(legacySpaceData) { space in
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
    }
}
