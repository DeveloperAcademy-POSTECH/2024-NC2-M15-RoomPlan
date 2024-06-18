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
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    var body: some View {
        if spaceData.isEmpty {
            Text("저장된 공간이 없습니다.")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(spaceData) { space in
                        Button(action: {
                            selectedSpace = space
                            showMySpaceDetailView = true
                        }, label: {
                            MySpaceCellView(space: space)
                        })
                    }
                }
            }
            .sheet(item: $selectedSpace) { space in
                MySpaceDetailView(space: space)
            }
        }
    }
}

#Preview {
    MySpacesView()
}
