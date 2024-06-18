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
        ZStack {
            Rectangle()
                .frame(width: 320, height: 495)
                .cornerRadius(19)
                .foregroundColor(.white)
                .overlay(
                    ZStack {
                        Image("bg")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 320, height: 495)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.gray, lineWidth: 2)
                        
                        
                    }
                        .padding(.bottom, 30)
                )
            Image("locationpin")
                .resizable()
                .frame(width:17, height:21)
                .padding(.bottom, 350)
                .padding(.trailing, 140)
            
            Text(comment)
                .frame(width: 300, height: 200)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 350)
                .padding(.leading, 30)
            
            Image("scanexport") //이 부분 오빠가 위에 함수 만들어둔 것 같은데 model이라고 쓰니까 오류떠서 뭐가 문젠지 모르겠어서 스캔 뜬 사진 에셋에 추가해서 임시로 넣어뒀어!
                .resizable()
                .frame(width:300, height:300)
            
            Text(date)
                .frame(width: 300, height: 200)
                .font(.system(size: 23, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.8))
                .padding(.top, 410)
                .padding(.leading, 120)
            
            Image("saveimage")
                .resizable()
                .frame(width:158, height:40)
                .padding(.top, 600)
                .padding(.trailing, 140)
            
            Image("share")
                .resizable()
                .frame(width:105, height:40)
                .padding(.top, 600)
                .padding(.leading, 180)
        }
    }
}

#Preview {
    MySpaceDetailView()
}
