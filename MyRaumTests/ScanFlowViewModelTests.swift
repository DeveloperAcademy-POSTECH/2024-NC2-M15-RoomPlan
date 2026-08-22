//
//  ScanFlowViewModelTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import CoreLocation
@testable import MyRaum

//스캔 플로우의 단계 전환과 저장 동작을 확인하는 테스트
@MainActor
struct ScanFlowViewModelTests {
    private func makeViewModel(
        scanner: FakeRoomScanner = FakeRoomScanner(),
        locationService: FakeLocationService = FakeLocationService(),
        repository: InMemorySpaceRepository? = nil
    ) -> ScanFlowViewModel {
        ScanFlowViewModel(
            scanner: scanner,
            modelCapturer: FakeModelCapturer(),
            locationService: locationService,
            spaceRepository: repository ?? InMemorySpaceRepository()
        )
    }
    
    @Test("초기 단계는 scan이고 스캔이 끝나지 않은 상태다")
    func initialState() {
        let viewModel = makeViewModel()
        
        #expect(viewModel.currentPage == .scan)
        #expect(viewModel.doneScanning == false)
    }
    
    @Test("스캔을 시작하면 세션이 실행되고 위치 권한을 확인한다")
    func startScanningRunsSessionAndChecksLocation() {
        let scanner = FakeRoomScanner()
        let locationService = FakeLocationService()
        let viewModel = makeViewModel(scanner: scanner, locationService: locationService)
        
        viewModel.startScanning()
        
        #expect(scanner.startCallCount == 1)
        #expect(locationService.checkCallCount == 1)
    }
    
    @Test("스캔을 끝내면 세션이 멈추고 doneScanning이 true가 된다")
    func finishScanningStopsSession() {
        let scanner = FakeRoomScanner()
        let viewModel = makeViewModel(scanner: scanner)
        
        viewModel.finishScanning()
        
        #expect(scanner.stopCallCount == 1)
        #expect(viewModel.doneScanning == true)
    }
    
    @Test("다시 스캔하면 scan 단계로 돌아가고 세션이 다시 실행된다")
    func restartScanningReturnsToScanPage() {
        let scanner = FakeRoomScanner()
        let viewModel = makeViewModel(scanner: scanner)
        viewModel.finishScanning()
        viewModel.currentPage = .scanResult
        
        viewModel.restartScanning()
        
        #expect(viewModel.currentPage == .scan)
        #expect(viewModel.doneScanning == false)
        #expect(scanner.startCallCount == 1)
    }
    
    @Test("장소 입력을 완료하면 addInfo 단계로 이동하고 팝업이 닫힌다")
    func confirmCommentMovesToAddInfo() {
        let viewModel = makeViewModel()
        viewModel.currentPage = .scanResult
        viewModel.showCommentPopup = true
        
        viewModel.confirmComment("작업실")
        
        #expect(viewModel.comment == "작업실")
        #expect(viewModel.currentPage == .addInfo)
        #expect(viewModel.showCommentPopup == false)
    }
    
    @Test("미리보기로 이동하면 날짜와 위치가 확정된다")
    func moveToFinalResultFixesDateAndLocation() {
        let locationService = FakeLocationService(
            lastKnownLocation: CLLocationCoordinate2D(latitude: 36.0190, longitude: 129.3435)
        )
        let viewModel = makeViewModel(locationService: locationService)
        viewModel.currentPage = .addInfo
        
        viewModel.moveToFinalResult()
        
        #expect(viewModel.currentPage == .finalResult)
        //yyyy.MM.dd 형식으로 날짜가 채워졌는지 확인
        #expect(viewModel.dateString?.wholeMatch(of: /\d{4}\.\d{2}\.\d{2}/) != nil)
    }
    
    @Test("모델과 배경이 모두 있으면 저장에 성공한다")
    func saveSucceedsWithModelAndBackground() {
        let repository = InMemorySpaceRepository()
        let locationService = FakeLocationService(
            lastKnownLocation: CLLocationCoordinate2D(latitude: 36.0190, longitude: 129.3435)
        )
        let viewModel = makeViewModel(locationService: locationService, repository: repository)
        viewModel.model = makeTestImage()
        viewModel.background = makeTestImage()
        viewModel.comment = "작업실"
        viewModel.moveToFinalResult()
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedSuccessAlert == true)
        #expect(viewModel.showSavedFailureAlert == false)
        #expect(repository.spaces.count == 1)
        #expect(repository.spaces.first?.comment == "작업실")
        #expect(repository.spaces.first?.latitude == 36.0190)
    }
    
    @Test("모델이 없으면 저장하지 않고 실패 알림을 보여준다")
    func saveFailsWithoutModel() {
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.background = makeTestImage()
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedFailureAlert == true)
        #expect(repository.spaces.isEmpty)
    }
    
    @Test("저장소가 실패를 리턴하면 실패 알림을 보여준다")
    func saveFailsWhenRepositoryFails() {
        let repository = InMemorySpaceRepository()
        repository.shouldFailToSave = true
        let viewModel = makeViewModel(repository: repository)
        viewModel.model = makeTestImage()
        viewModel.background = makeTestImage()
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedFailureAlert == true)
        #expect(viewModel.showSavedSuccessAlert == false)
    }
    
    @Test("저장 후 상태를 되돌리면 scan 단계로 돌아간다")
    func resetAfterSaveReturnsToScan() {
        let viewModel = makeViewModel()
        viewModel.finishScanning()
        viewModel.currentPage = .finalResult
        
        viewModel.resetAfterSave()
        
        #expect(viewModel.currentPage == .scan)
        #expect(viewModel.doneScanning == false)
    }
}
