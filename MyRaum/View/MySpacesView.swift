//
//  MySpacesView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData

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
        if spaceData.isEmpty {
            VStack {
                Image("scanexport")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250)
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
                            .onLongPressGesture(minimumDuration: 0.3) {
                                spaceToDelete = space
                                showDeleteConfirmation = true
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("보관함")
            .navigationBarTitleDisplayMode(.inline)
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
