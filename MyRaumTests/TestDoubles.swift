//
//  TestDoubles.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import CoreLocation
import UIKit
import RoomPlan
@testable import MyRaum

//스캔 세션 호출 여부만 기록하는 테스트용 스캐너
final class FakeRoomScanner: RoomScanning {
    var capturedRoom: CapturedRoom?
    private(set) var capturedRooms: [CapturedRoom] = []
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var keepForStructureCallCount = 0
    
    func startSession() { startCallCount += 1 }
    func stopSession() { stopCallCount += 1 }
    func keepCurrentRoomForStructure() { keepForStructureCallCount += 1 }
}

//지정한 좌표를 그대로 돌려주는 테스트용 위치 서비스
final class FakeLocationService: LocationProviding {
    var lastKnownLocation: CLLocationCoordinate2D?
    private(set) var checkCallCount = 0
    
    init(lastKnownLocation: CLLocationCoordinate2D? = nil) {
        self.lastKnownLocation = lastKnownLocation
    }
    
    func checkLocationAuthorization() { checkCallCount += 1 }
}

//파일을 실제로 쓰지 않는 테스트용 모델 파일 저장소
final class FakeModelFileStore: ModelFileStoring {
    var exportedFileName: String? = "test.usdz"
    var exportError: Error?
    //url(forFileName:)이 돌려줄 값. nil이면 파일이 없는 상황을 뜻한다
    var urlForAnyFile: URL?
    private(set) var deletedFileNames: [String] = []
    private(set) var writtenIDs: [UUID] = []
    
    func export(_ room: CapturedRoom, id: UUID) throws -> String {
        if let exportError { throw exportError }
        return exportedFileName ?? "\(id.uuidString).usdz"
    }
    
    func exportStructure(_ structure: CapturedStructure, id: UUID) throws -> String {
        "structure-\(id.uuidString).usdz"
    }
    
    func write(_ data: Data, id: UUID) throws -> String {
        writtenIDs.append(id)
        return "\(id.uuidString).usdz"
    }
    
    func url(forFileName fileName: String) -> URL? { urlForAnyFile }
    
    func delete(fileName: String) { deletedFileNames.append(fileName) }
}

//썸네일을 만들지 않는 테스트용 렌더러
final class FakeThumbnailRenderer: ThumbnailRendering {
    var thumbnailData: Data?
    
    func renderThumbnail(of modelURL: URL, size: CGSize) -> Data? { thumbnailData }
}

//USDZ 내보내기를 흉내내는 테스트용 서비스
final class FakeRoomExporter: RoomExporting {
    var result: ExportedRoom?
    var error: Error?
    private(set) var exportCallCount = 0
    
    init(result: ExportedRoom? = nil, error: Error? = nil) {
        self.result = result
        self.error = error
    }
    
    //MultiRoom에서 방마다 다른 파일이 나오도록 두 번째 호출부터 순번을 붙인다
    func exportCurrentScan(id: UUID) throws -> ExportedRoom {
        exportCallCount += 1
        if let error { throw error }
        guard let result else { throw RoomExportError.noCapturedRoom }
        
        guard exportCallCount > 1 else { return result }
        
        return ExportedRoom(
            fileName: "\(exportCallCount)-\(result.fileName)",
            thumbnailData: result.thumbnailData,
            metrics: result.metrics
        )
    }
    
    var mergedStructureFileName: String?
    private(set) var mergeCallCount = 0
    
    func exportMergedStructure(id: UUID) async -> String? {
        mergeCallCount += 1
        return mergedStructureFileName
    }
}

//테스트용 내보내기 결과를 만드는 함수
func makeExportedRoom(
    fileName: String = "test.usdz",
    furniture: [CapturedFurniture] = [],
    floorAreaSqM: Double? = 12.5,
    roomType: RoomTypeGuess = .bedroom
) -> ExportedRoom {
    ExportedRoom(
        fileName: fileName,
        thumbnailData: makeTestImage().pngData(),
        metrics: RoomMetrics(floorAreaSqM: floorAreaSqM, roomType: roomType, furniture: furniture)
    )
}

//테스트용 가구 항목을 만드는 함수
func makeFurniture(category: String, confidence: String = "high") -> CapturedFurniture {
    CapturedFurniture(
        id: UUID(),
        category: category,
        width: 1.0,
        height: 0.5,
        length: 2.0,
        confidence: confidence,
        transform: Array(repeating: 0.0, count: 16)
    )
}

//저장·삭제 호출을 메모리에 기록하는 테스트용 저장소
@MainActor
final class InMemorySpaceRepository: SpaceRepository {
    private(set) var spaces: [SpaceData] = []
    var shouldFailToSave = false
    private(set) var saveChangesCallCount = 0
    
    @discardableResult
    func save(_ space: SpaceData) -> Bool {
        if shouldFailToSave { return false }
        spaces.append(space)
        return true
    }
    
    func delete(_ space: SpaceData) {
        spaces.removeAll { $0.id == space.id }
    }
    
    func fetchAll() -> [SpaceData] { spaces }
    
    func count(of kind: SpaceStorageKind) -> Int {
        spaces.filter { $0.kind == kind }.count
    }
    
    func fetchPendingUpload() -> [SpaceData] {
        spaces.filter { $0.kind == .usdz && ($0.sync == .pending || $0.sync == .failed) }
    }
    
    func saveChanges() {
        saveChangesCallCount += 1
    }
}

//로그인 상태를 흉내내는 테스트용 인증 서비스
@MainActor
final class FakeAuthService: AuthProviding {
    private(set) var currentUserID: String?
    var signInError: Error?
    private(set) var signOutCallCount = 0
    private(set) var deleteAccountCallCount = 0
    
    init(currentUserID: String? = nil) {
        self.currentUserID = currentUserID
    }
    
    func restoreSession() async {}
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        if let signInError { throw signInError }
        currentUserID = "test-user"
    }
    
    func signOut() async throws {
        signOutCallCount += 1
        currentUserID = nil
    }
    
    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        currentUserID = nil
    }
}

//온보딩 완료 여부를 메모리에 두는 테스트용 저장소
final class InMemoryOnboardingStore: OnboardingStateStoring {
    var hasCompletedOnboarding: Bool
    
    init(hasCompletedOnboarding: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

//업로드 호출을 기록하는 테스트용 원격 저장소
final class FakeRemoteSpaceRepository: RemoteSpaceRepositoryProtocol, @unchecked Sendable {
    var uploadError: Error?
    var remoteSpaces: [RemoteSpace] = []
    private(set) var uploadedIDs: [UUID] = []
    private(set) var visibilityUpdates: [(String, Bool)] = []
    //처음 몇 번은 실패하게 만들어 재시도를 확인한다
    var failuresBeforeSuccess = 0
    
    func upload(_ payload: RemoteUploadPayload) async throws -> String {
        if failuresBeforeSuccess > 0 {
            failuresBeforeSuccess -= 1
            throw RemoteSpaceError.notConfigured
        }
        if let uploadError { throw uploadError }
        uploadedIDs.append(payload.id)
        return payload.id.uuidString
    }
    
    func updateIsPublic(remoteID: String, isPublic: Bool) async throws {
        visibilityUpdates.append((remoteID, isPublic))
    }
    
    func delete(remoteID: String) async throws {}
    
    func fetchMySpaces() async throws -> [RemoteSpace] { remoteSpaces }
    
    func downloadModel(storagePath: String) async throws -> Data { Data([0x55, 0x53, 0x44, 0x5A]) }
    
    func downloadThumbnail(thumbnailPath: String) async throws -> Data { Data([0x50, 0x4E, 0x47]) }
}

//테스트용 더미 공간 데이터를 만드는 함수
func makeSpaceData(
    comment: String = "작업실",
    createdAt: Date = Date(timeIntervalSince1970: 1_787_000_000),
    storageKind: SpaceStorageKind = .usdz,
    modelFileName: String? = "test.usdz"
) -> SpaceData {
    SpaceData(
        id: UUID(),
        createdAt: createdAt,
        comment: comment,
        latitude: 36.0190,
        longitude: 129.3435,
        storageKind: storageKind,
        background: Data([0x02]),
        modelFileName: modelFileName,
        thumbnail: Data([0x01]),
        syncState: storageKind == .usdz ? .pending : .localOnly
    )
}

//1x1 크기의 단색 이미지를 만드는 함수
func makeTestImage() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}
