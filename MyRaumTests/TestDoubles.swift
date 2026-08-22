//
//  TestDoubles.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import CoreLocation
import UIKit
@testable import MyRaum

//스캔 세션 호출 여부만 기록하는 테스트용 스캐너
final class FakeRoomScanner: RoomScanning {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    
    func startSession() { startCallCount += 1 }
    func stopSession() { stopCallCount += 1 }
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

//누끼 처리를 실제로 하지 않는 테스트용 모델 캡쳐 서비스
final class FakeModelCapturer: ModelCapturing {
    var screenImage: UIImage?
    var stickerImage: UIImage?
    
    func captureScreen() -> UIImage? { screenImage }
    func createSticker(image: UIImage) async -> UIImage? { stickerImage }
}

//저장·삭제 호출을 메모리에 기록하는 테스트용 저장소
@MainActor
final class InMemorySpaceRepository: SpaceRepository {
    private(set) var spaces: [SpaceData] = []
    var shouldFailToSave = false
    
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
}

//테스트용 더미 공간 데이터를 만드는 함수
func makeSpaceData(comment: String = "작업실", date: String = "2026.08.22") -> SpaceData {
    SpaceData(
        id: UUID(),
        date: date,
        comment: comment,
        model: Data([0x01]),
        background: Data([0x02]),
        latitude: 36.0190,
        longitude: 129.3435
    )
}

//1x1 크기의 단색 이미지를 만드는 함수
func makeTestImage() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}
