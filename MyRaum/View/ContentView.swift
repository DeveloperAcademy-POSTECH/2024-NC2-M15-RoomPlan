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
    
    @State private var isDragging = false
    @State private var shouldNavigate = false
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in
                self.isDragging = true
            }
            .onEnded { gesture in
                self.isDragging = false
                if gesture.translation.width < -50 && gesture.translation.height < -50 {
                    self.shouldNavigate = true
                }
            }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    
                    NavigationLink(destination: InfoView()) {
                        Image(systemName: "info.circle")
                            .font(.title)
                            .foregroundStyle(Color.gray)
                            .padding(.top, 70)
                            .padding(.trailing, 30)
                    }
                }
                
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
                    Image("corner")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                        .offset(x: 10)
                        .navigationDestination(isPresented: $shouldNavigate, destination: {
                            MySpacesView()
                        })
                        .navigationTitle("")
                        .onTapGesture {
                            self.shouldNavigate = true
                        }
                        .gesture(dragGesture)
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
