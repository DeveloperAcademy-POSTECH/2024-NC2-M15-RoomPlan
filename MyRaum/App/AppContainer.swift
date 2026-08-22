//
//  AppContainer.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import SwiftData
import Supabase

//앱이 사용하는 서비스 인스턴스를 소유하고 뷰에 주입하는 DI 컨테이너
@Observable
@MainActor
final class AppContainer {
    let locationService: any LocationProviding
    let spaceRepository: any SpaceRepository
    let remoteSpaceRepository: any RemoteSpaceRepositoryProtocol
    let modelFileStore: any ModelFileStoring
    let thumbnailRenderer: any ThumbnailRendering
    let authService: any AuthProviding
    let syncQueue: SyncQueue
    let remoteRestoreService: RemoteRestoreService
    //Supabase 설정이 없으면 원격 기능이 꺼진다
    let isRemoteConfigured: Bool
    
    //스캔 세션은 스캔할 때마다 새로 만들어야 하므로 인스턴스가 아닌 생성 함수를 보관
    private let roomScannerFactory: () -> any RoomScanner
    
    init(
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository,
        remoteSpaceRepository: any RemoteSpaceRepositoryProtocol,
        modelFileStore: any ModelFileStoring,
        thumbnailRenderer: any ThumbnailRendering,
        authService: any AuthProviding,
        isRemoteConfigured: Bool,
        roomScannerFactory: @escaping () -> any RoomScanner
    ) {
        self.locationService = locationService
        self.spaceRepository = spaceRepository
        self.remoteSpaceRepository = remoteSpaceRepository
        self.modelFileStore = modelFileStore
        self.thumbnailRenderer = thumbnailRenderer
        self.authService = authService
        self.isRemoteConfigured = isRemoteConfigured
        self.roomScannerFactory = roomScannerFactory
        self.syncQueue = SyncQueue(
            localRepository: spaceRepository,
            remoteRepository: remoteSpaceRepository,
            modelFileStore: modelFileStore,
            authService: authService
        )
        self.remoteRestoreService = RemoteRestoreService(
            localRepository: spaceRepository,
            remoteRepository: remoteSpaceRepository,
            modelFileStore: modelFileStore
        )
    }
    
    //실제 앱에서 사용하는 기본 구성
    convenience init(modelContext: ModelContext) {
        let modelFileStore = ModelFileStore()
        let config = SupabaseConfig.loadFromBundle()
        
        let authService: any AuthProviding
        let remoteRepository: any RemoteSpaceRepositoryProtocol
        
        if let config {
            let client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
            authService = SupabaseAuthService(client: client)
            remoteRepository = SupabaseSpaceRepository(client: client)
        } else {
            authService = UnconfiguredAuthService()
            remoteRepository = UnconfiguredRemoteSpaceRepository()
        }
        
        self.init(
            locationService: LocationManager(),
            spaceRepository: LocalSpaceRepository(modelContext: modelContext, modelFileStore: modelFileStore),
            remoteSpaceRepository: remoteRepository,
            modelFileStore: modelFileStore,
            thumbnailRenderer: ThumbnailRenderer(),
            authService: authService,
            isRemoteConfigured: config != nil,
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
    
    func makeRouter() -> AppRouter {
        AppRouter(
            authService: authService,
            onboardingStore: OnboardingStateStore(),
            legacyCardCount: { [spaceRepository] in spaceRepository.count(of: .legacyImage) }
        )
    }
}
