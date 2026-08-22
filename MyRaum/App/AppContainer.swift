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
    let modelFileStore: any ModelFileStoring
    let thumbnailRenderer: any ThumbnailRendering
    
    //스캔 세션은 스캔할 때마다 새로 만들어야 하므로 인스턴스가 아닌 생성 함수를 보관
    private let roomScannerFactory: () -> any RoomScanner
    
    init(
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository,
        modelFileStore: any ModelFileStoring,
        thumbnailRenderer: any ThumbnailRendering,
        roomScannerFactory: @escaping () -> any RoomScanner
    ) {
        self.locationService = locationService
        self.spaceRepository = spaceRepository
        self.modelFileStore = modelFileStore
        self.thumbnailRenderer = thumbnailRenderer
        self.roomScannerFactory = roomScannerFactory
    }
    
    //실제 앱에서 사용하는 기본 구성
    convenience init(modelContext: ModelContext) {
        let modelFileStore = ModelFileStore()
        
        self.init(
            locationService: LocationManager(),
            spaceRepository: LocalSpaceRepository(modelContext: modelContext, modelFileStore: modelFileStore),
            modelFileStore: modelFileStore,
            thumbnailRenderer: ThumbnailRenderer(),
            roomScannerFactory: { RoomPlanManager() }
        )
    }
    
    func makeRoomScanner() -> any RoomScanner {
        roomScannerFactory()
    }
    
    //스캔 한 번에 대응하는 내보내기 서비스를 만드는 함수
    func makeRoomExporter(scanner: any RoomScanning) -> any RoomExporting {
        RoomExportService(
            scanner: scanner,
            modelFileStore: modelFileStore,
            thumbnailRenderer: thumbnailRenderer
        )
    }
}
