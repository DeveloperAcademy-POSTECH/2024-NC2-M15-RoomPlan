//
//  StructureDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//구조에 묶인 방들을 펼쳐 보여주는 화면 (8.1)
struct StructureDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var container
    
    let group: SpaceGroup
    
    @State private var selectedSpace: SpaceData? = nil
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                //병합된 "집 전체" 모델이 있으면 먼저 보여준다
                if let structureModelURL {
                    Space3DView(modelURL: structureModelURL)
                        .frame(height: 280)
                        .padding(.bottom, 8)
                        .accessibilityLabel(Text("집 전체 3D 모델"))
                }
                
                totalAreaBadge
                
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(group.rooms) { room in
                        VStack(spacing: 8) {
                            SpaceCellView(space: room)
                            
                            Text(room.comment.isEmpty ? String(localized: "이름 없는 방") : room.comment)
                                .font(.footnote)
                                .foregroundStyle(Color.gray)
                        }
                        .onTapGesture {
                            selectedSpace = room
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle(group.representative?.comment ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .bold()
                    }
                    .accessibilityLabel(Text("닫기"))
                }
            }
            .sheet(item: $selectedSpace) { room in
                MySpaceDetailView(space: room)
            }
        }
    }
}

private extension StructureDetailView {
    var structureModelURL: URL? {
        guard let fileName = group.representative?.structureModelFileName else { return nil }
        return container.modelFileStore.url(forFileName: fileName)
    }
    
    //구조 전체 면적을 합산해 보여준다
    @ViewBuilder
    var totalAreaBadge: some View {
        let totalArea = group.rooms.compactMap(\.floorAreaSqM).reduce(0, +)
        
        HStack(spacing: 8) {
            Label {
                Text("\(group.roomCount)개의 방")
            } icon: {
                Image(systemName: "square.split.bottomrightquarter")
            }
            
            if totalArea > 0 {
                Label {
                    Text(verbatim: String(format: "%.1f m²", totalArea))
                } icon: {
                    Image(systemName: "ruler")
                }
            }
        }
        .font(.system(size: 14))
        .foregroundStyle(Color.gray)
        .padding(.bottom, 8)
    }
}
