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
    
    @State private var comment: String = "체인지업그라운드"
    @State private var date: String = "2024년 6월 14일"
    @State private var model: Image = Image(systemName: "plus")
    @State private var background: Image = Image(systemName: "person")
    
    var body: some View {
        //위에 있는 더미 변수로 카드 만들어주셔용~나중에 데이터 연결은 제가 합니당
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    MySpaceDetailView()
}
