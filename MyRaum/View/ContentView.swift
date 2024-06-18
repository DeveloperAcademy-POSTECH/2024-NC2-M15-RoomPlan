//
//  ContentView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Spacer()
                
                //디자인된 로고 이미지로 대체
                Text("MY RAUM")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 50)
                
                Text("나의 공간과 추억을\n생생하게 기록해보세요.")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 50)
                
                NavigationLink(destination: RoomPlanView()) {
                    Text("스캔하기")
                        .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .cornerRadius(30)
                
                Spacer()
                
                NavigationLink(destination: MySpacesView()) {
                    HStack {
                        Spacer()
                        
                        //디자인된 보관함 버튼 이미지로 대체
                        Text("보관함")
                            .foregroundStyle(Color.white)
                            .padding()
                    }
                }
                .toolbarTitleMenu {
                    Text("보관함")
                }
            }
            .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
