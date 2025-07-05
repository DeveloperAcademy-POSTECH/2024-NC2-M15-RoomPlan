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
    
    @State private var navigateToRoomPlanView: Bool = false
    @State private var navigateToMySpaceView: Bool = false
    @State private var isDragging: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
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
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                
                Text("나의 공간과 추억을\n생생하게 기록해보세요.")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                
                //공간 스캔 화면으로 이동
                TextButtonCapsule(text: "스캔하기", color: .white) {
                    navigateToRoomPlanView = true
                }
                .padding(.leading, 30)
                .navigationDestination(isPresented: $navigateToRoomPlanView) {
                    RoomPlanView()
                }
                
                Spacer()
                
                HStack {
                    Text("[Version \(AppEnvironment.version)]")
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
                        .navigationDestination(isPresented: $navigateToMySpaceView, destination: {
                            MySpacesView()
                        })
                        .navigationTitle("")
                        .onTapGesture {
                            navigateToMySpaceView = true
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

private extension ContentView {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in
                self.isDragging = true
            }
            .onEnded { gesture in
                self.isDragging = false
                if gesture.translation.width < -50 && gesture.translation.height < -50 {
                    navigateToMySpaceView = true
                }
            }
    }
}

#Preview {
    ContentView()
}
