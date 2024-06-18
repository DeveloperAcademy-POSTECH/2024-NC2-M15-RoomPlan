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
    
    var body: some View {
        if spaceData.isEmpty {
            Text("저장된 공간이 없습니다.")
        } else {
            List {
                ForEach(spaceData) { space in
                    HStack {
                        Image(uiImage: UIImage(data: space.model)!)
                        
                        Text(space.comment)
                    }
                }
            }
        }
    }
}

#Preview {
    MySpacesView()
}
