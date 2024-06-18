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
                
                HStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280)
                        .padding(.leading, 30)
                        .padding(.bottom, 30)
                    
                    Spacer()
                }
                
                HStack {
                    Text("나의 공간과 추억을\n생생하게 기록해보세요.")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 30)
                        .padding(.bottom, 30)
                    
                    Spacer()
                }
                
                HStack {
                    NavigationLink(destination: RoomPlanView()) {
                        Image("scan")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                    }
                    .padding(.leading, 30)
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    NavigationLink(destination: MySpacesView()) {
                        Image("corner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200)
                    }
                }
            }
            .background(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
