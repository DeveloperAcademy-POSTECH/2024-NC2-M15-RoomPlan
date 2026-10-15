//
//  AppRoute.swift
//  MyRaum
//
//  Created by Yune Cho on 10/11/26.
//

//메인화면의 NavigationStack에서 이동할 수 있는 화면들
//새로운 화면을 추가할 때는 case를 추가하고 ContentView의 destination(for:)에서 연결
enum AppRoute: Hashable {
    case spaceScan
    case mySpaces
    case legacySpaces
    case myPage
}
