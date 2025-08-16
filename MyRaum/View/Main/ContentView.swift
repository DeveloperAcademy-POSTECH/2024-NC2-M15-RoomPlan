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
                    
                    NavigationLink {
                        MyPageView()
                    } label: {
                        if #available(iOS 18.0, *) {
                            Image(systemName: "person.crop.circle")
                                .font(.title)
                                .foregroundStyle(Color.gray)
                                .padding(.top, 70)
                                .padding(.trailing, 16)
                                .symbolEffect(.breathe, options: .nonRepeating)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.title)
                                .foregroundStyle(Color.gray)
                                .padding(.top, 70)
                                .padding(.trailing, 16)
                        }
                    }
                }
                
                Spacer()
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                
                Text("나의 공간을 기록해보세요.")
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
                    Spacer()
                    
                    //보관함으로 이동
                    Image("corner")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                        .overlay(alignment: .bottomTrailing, content: {
                            Text("보관함")
                                .font(.title3)
                                .foregroundStyle(Color.black)
                                .padding(24)
                        })
                        .navigationDestination(isPresented: $navigateToMySpaceView, destination: {
                            MySpacesView()
                        })
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
