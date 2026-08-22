//
//  AppContainer.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import SwiftData

//앱이 사용하는 서비스 인스턴스를 소유하고 뷰에 주입하는 DI 컨테이너
@Observable
@MainActor
final class AppContainer {
    let locationService: any LocationProviding
    let spaceRepository: any SpaceRepository
    
    //스캔 세션은 스캔할 때마다 새로 만들어야 하므로 인스턴스가 아닌 생성 함수를 보관
    private let roomScannerFactory: () -> any RoomScanner
    private let modelCapturerFactory: () -> any ModelCapturing
    
    init(
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository,
        roomScannerFactory: @escaping () -> any RoomScanner,
        modelCapturerFactory: @escaping () -> any ModelCapturing
    ) {
        self.locationService = locationService
        self.spaceRepository = spaceRepository
        self.roomScannerFactory = roomScannerFactory
        self.modelCapturerFactory = modelCapturerFactory
    }
    
    //실제 앱에서 사용하는 기본 구성
    convenience init(modelContext: ModelContext) {
        self.init(
            locationService: LocationManager(),
            spaceRepository: LocalSpaceRepository(modelContext: modelContext),
            roomScannerFactory: { RoomPlanManager() },
            modelCapturerFactory: { ModelCaptureManager() }
        )
    }
    
    func makeRoomScanner() -> any RoomScanner {
        roomScannerFactory()
    }
    
    func makeModelCapturer() -> any ModelCapturing {
        modelCapturerFactory()
    }
}
