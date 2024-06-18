//
//  MySpaceDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData

struct MySpaceDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var spaceData: [SpaceData]
    
    var body: some View {
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    MySpaceDetailView()
}
