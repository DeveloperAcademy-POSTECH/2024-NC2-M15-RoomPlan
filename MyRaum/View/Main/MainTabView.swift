//
//  MainTabView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/16/26.
//

import SwiftUI

//하단 탭바 - 홈, 보관함, 지도, 내 정보
//각 탭은 자신만의 NavigationStack을 가짐
//스캔 화면은 탭바가 숨겨졌다가 다시 나타나면서 화면이 흔들리지 않도록 전체 화면으로 띄움
struct MainTabView: View {
    private enum Tab {
        case home
        case archive
        case map
        case myPage
    }

    @State private var selectedTab: Tab = .home
    @State private var showSpaceScan: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            tabStack {
                ContentView {
                    showSpaceScan = true
                }
            }
            .tabItem {
                Label("홈", systemImage: "house")
            }
            .tag(Tab.home)

            tabStack {
                MySpacesView()
            }
            .tabItem {
                Label("보관함", systemImage: "square.stack")
            }
            .tag(Tab.archive)

            tabStack {
                SpaceMapView()
            }
            .tabItem {
                Label("지도", systemImage: "map")
            }
            .tag(Tab.map)

            tabStack {
                MyPageView()
            }
            .tabItem {
                Label("내 정보", systemImage: "person.crop.circle")
            }
            .tag(Tab.myPage)
        }
        //라이트/다크 모드와 탭바 배경에 따라 흰색 또는 검은색으로 표시
        .tint(Color.primary)
        .fullScreenCover(isPresented: $showSpaceScan) {
            RoomPlanView()
        }
    }
}

private extension MainTabView {
    func tabStack<Root: View>(@ViewBuilder root: () -> Root) -> some View {
        NavigationStack {
            root()
                .navigationDestination(for: AppRoute.self, destination: destination(for:))
        }
    }

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .legacySpaces:
            LegacySpacesView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [SpaceRecord.self, SpaceData.self], inMemory: true)
}
