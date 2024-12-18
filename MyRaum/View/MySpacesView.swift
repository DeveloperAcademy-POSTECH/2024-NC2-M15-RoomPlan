//
//  MySpacesView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData

//보관함 화면
struct MySpacesView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var spaceData: [SpaceData]
    
    @State private var selectedSpace: SpaceData? = nil
    @State private var showMySpaceDetailView = false
    @State private var spaceToDelete: SpaceData? = nil
    @State private var showDeleteConfirmation = false
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    var body: some View {
        //저장된 데이터가 없으면 저장된 공간이 없다고 노출되고, 저장된 데이터가 있을 경우 LazyVGrid 방식으로 장소 카드들을 보여줌
        if spaceData.isEmpty {
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
                    .navigationTitle("보관함")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(spaceData) { space in
                        MySpaceCellView(space: space)
                            .onTapGesture {
                                selectedSpace = space
                                showMySpaceDetailView = true
                            }
                            .onLongPressGesture(minimumDuration: 0.3, perform: {
                                spaceToDelete = space
                                showDeleteConfirmation = true
                            })
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("보관함")
            .navigationBarTitleDisplayMode(.inline)
            .defaultScrollAnchor(.bottom)
            .padding(.top)
            .sheet(item: $selectedSpace) { space in
                MySpaceDetailView(space: space)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("공간 삭제"),
                    message: Text("이 공간을 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        if let space = spaceToDelete {
                            deleteSpace(space: space)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    //SwiftData에서 데이터를 삭제하는 함수
    func deleteSpace(space: SpaceData) {
        do {
            modelContext.delete(space)
            try modelContext.save()
        } catch {
            print("Failed to save data")
        }
    }
}

#Preview {
    MySpacesView()
}
