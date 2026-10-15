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

    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()

                    NavigationLink(value: AppRoute.myPage) {
                        myPageIcon
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
                    path.append(.spaceScan)
                }
                .padding(.leading, 30)

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
                        .onTapGesture {
                            path.append(.mySpaces)
                        }
                        .gesture(dragGesture)
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(colorScheme == .dark ? .white : .black)
    }
}

private extension ContentView {
    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .spaceScan:
            RoomPlanView()
        case .mySpaces:
            MySpacesView()
        case .legacySpaces:
            LegacySpacesView()
        case .myPage:
            MyPageView()
        }
    }

    @ViewBuilder
    var myPageIcon: some View {
        let icon = Image(systemName: "person.crop.circle")
            .font(.title)
            .foregroundStyle(Color.gray)
            .padding(.top, 70)
            .padding(.trailing, 16)

        if #available(iOS 18.0, *) {
            icon.symbolEffect(.breathe, options: .nonRepeating)
        } else {
            icon
        }
    }

    //보관함 이미지를 왼쪽 위로 드래그하면 보관함으로 이동
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { gesture in
                if gesture.translation.width < -50 && gesture.translation.height < -50 {
                    path.append(.mySpaces)
                }
            }
    }
}

#Preview {
    ContentView()
}
