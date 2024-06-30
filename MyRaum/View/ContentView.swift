//
//  ContentView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//앱 메인화면
struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
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
                    //공간 스캔 화면으로 이동
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
                    Text("[Version \(version)]")
                        .foregroundStyle(Color.gray)
                        .opacity(0.5)
                        .font(.caption)
                        .padding(.top, 80)
                        .padding(.leading, 30)
                    
                    Spacer()
                    
                    //보관함으로 이동
                    NavigationLink(destination: MySpacesView()) {
                        Image("corner")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                            .offset(x: 10)
                    }
                    .navigationTitle("")
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
        .tint(colorScheme == .dark ? .white : .black)
    }
}

#Preview {
    ContentView()
}
