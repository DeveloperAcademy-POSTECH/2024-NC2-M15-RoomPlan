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
    if RoomCaptureSession.isSupported {
        ContentView()
    } else {
        UnsupportedDeviceView()
    }
}
