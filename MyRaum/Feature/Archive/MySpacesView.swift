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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var spaceData: [SpaceData]
    
    @State private var selectedSpace: SpaceData? = nil
    @State private var showMySpaceDetailView: Bool = false
    @State private var spaceToDelete: SpaceData? = nil
    @State private var showDeleteConfirmation: Bool = false
    
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
                .padding(.top, 4)
                .padding(.horizontal, 20)
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
            }
            .padding(.top)
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
        }
    }
}

#Preview {
    NavigationStack {
        MySpacesView()
    }
}
