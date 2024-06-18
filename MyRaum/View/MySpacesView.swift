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
    
    private let columns = [
        GridItem(.flexible(minimum: 200, maximum: 300), spacing: nil, alignment: .top),
        GridItem(.flexible(minimum: 200, maximum: 300), spacing: nil, alignment: .top)
    ]
    
    var body: some View {
        if spaceData.isEmpty {
            Text("저장된 공간이 없습니다.")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(spaceData) { space in
                        //임시뷰
                        ZStack {
                            Image(uiImage: UIImage(data: space.background)!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150)
                            
                            Image(uiImage: UIImage(data: space.model)!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150)
                            
                            Text(space.comment)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MySpacesView()
}
