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
    @State private var appSettingsManager = AppSettingsManager()
    @State private var appContainer: AppContainer
    
    private let modelContainer: ModelContainer
    
    init() {
        let modelContainer = MyRaumApp.makeModelContainer()
        self.modelContainer = modelContainer
        _appContainer = State(initialValue: AppContainer(modelContext: modelContainer.mainContext))
    }
    
    var body: some Scene {
        WindowGroup {
            checkDeciveView()
        }
        .modelContainer(modelContainer)
        .environment(appContainer)
        .environment(appSettingsManager)
        .environment(\.locale, appSettingsManager.effectiveLocale)
    }
    
    //디스크 저장소를 열지 못하면 인메모리 저장소로 대체해 앱이 바로 종료되지 않도록 함
    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: SpaceData.self)
        } catch {
            print("Failed to create ModelContainer: \(error)")
            
            do {
                return try ModelContainer(
                    for: SpaceData.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Failed to create in-memory ModelContainer: \(error)")
            }
        }
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
