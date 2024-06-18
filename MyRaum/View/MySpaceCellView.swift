//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

struct MySpaceCellView: View {
    @State private var comment: String = "체인지업그라운드"
    @State private var background: Image = Image(systemName: "person")
    
    var body: some View {
        //위에 있는 더미 변수로 카드 만들어주셔용~나중에 데이터 연결은 제가 합니당
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    MySpaceCellView()
}
