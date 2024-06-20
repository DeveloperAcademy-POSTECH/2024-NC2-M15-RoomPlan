//
//  MyRaumApp.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData
import RoomPlan

@main
struct MyRaumApp: App {
    var body: some Scene {
        WindowGroup {
            checkDeciveView()
        }
        .modelContainer(for: SpaceData.self)
    }
}

@ViewBuilder
func checkDeciveView() -> some View {
    //RoomPlan을 지원하는 기기일 경우 메인화면을 보여주고, 지원하지 않는 기기일 경우 기기 미지원 화면 보여줌
    if RoomCaptureSession.isSupported {
        ContentView()
    } else {
        UnsupportedDeviceView()
    }
}
