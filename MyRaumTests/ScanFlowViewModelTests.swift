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
        repository: InMemorySpaceRepository? = nil,
        exporter: FakeRoomExporter? = nil
    ) -> ScanFlowViewModel {
        ScanFlowViewModel(
            scanner: scanner,
            locationService: locationService,
            spaceRepository: repository ?? InMemorySpaceRepository(),
            roomExporter: exporter ?? FakeRoomExporter(result: makeExportedRoom()),
            modelFileStore: FakeModelFileStore()
        )
    }
    
    @Test("초기 단계는 capture이고 스캔이 끝나지 않은 상태다")
    func initialState() {
        let viewModel = makeViewModel()
        
        #expect(viewModel.currentStep == .capture)
        #expect(viewModel.doneScanning == false)
        #expect(viewModel.showsDate == true)
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
    
    @Test("스캔을 끝내면 세션이 멈추고 바로 편집 캔버스로 넘어간다")
    func finishScanningMovesToEditor() {
        let scanner = FakeRoomScanner()
        let exporter = FakeRoomExporter(result: makeExportedRoom(fileName: "room.usdz"))
        let viewModel = makeViewModel(scanner: scanner, exporter: exporter)
        
        viewModel.finishScanning()
        
        #expect(scanner.stopCallCount == 1)
        #expect(viewModel.doneScanning == true)
        //화면 전환 없이 편집으로 이어지도록 USDZ까지 여기서 만들어 둔다
        #expect(viewModel.currentStep == .edit)
        #expect(viewModel.modelFileName == "room.usdz")
        #expect(exporter.exportCallCount == 1)
    }
    
    @Test("내보내기에 실패하면 편집 캔버스로 넘어가지 않는다")
    func finishScanningStaysOnFailure() {
        let viewModel = makeViewModel(exporter: FakeRoomExporter(error: RoomExportError.noCapturedRoom))
        
        viewModel.finishScanning()
        
        #expect(viewModel.currentStep == .capture)
        #expect(viewModel.showExportFailureAlert == true)
    }
    
    @Test("다시 스캔하면 capture 단계로 돌아가고 내보낸 모델 정보가 지워진다")
    func restartScanningClearsExportedModel() {
        let scanner = FakeRoomScanner()
        let viewModel = makeViewModel(scanner: scanner)
        viewModel.prepareModel()
        #expect(viewModel.thumbnail != nil)
        
        viewModel.restartScanning()
        
        #expect(viewModel.currentStep == .capture)
        #expect(viewModel.doneScanning == false)
        #expect(viewModel.thumbnail == nil)
        #expect(scanner.startCallCount == 1)
    }
    
    @Test("모델을 내보내면 썸네일과 파생 데이터가 채워진다")
    func prepareModelFillsThumbnailAndMetrics() {
        let exporter = FakeRoomExporter(
            result: makeExportedRoom(furniture: [makeFurniture(category: "bed")], floorAreaSqM: 18.2, roomType: .bedroom)
        )
        let viewModel = makeViewModel(exporter: exporter)
        
        #expect(viewModel.prepareModel() == true)
        #expect(viewModel.thumbnail != nil)
        #expect(viewModel.metrics?.floorAreaSqM == 18.2)
        #expect(viewModel.metrics?.roomType == .bedroom)
    }
    
    @Test("이미 내보낸 모델이 있으면 다시 내보내지 않는다")
    func prepareModelIsIdempotent() {
        let exporter = FakeRoomExporter(result: makeExportedRoom())
        let viewModel = makeViewModel(exporter: exporter)
        
        viewModel.prepareModel()
        viewModel.prepareModel()
        
        #expect(exporter.exportCallCount == 1)
    }
    
    @Test("내보내기에 실패하면 실패 알림을 보여준다")
    func prepareModelFailureShowsAlert() {
        let exporter = FakeRoomExporter(error: RoomExportError.noCapturedRoom)
        let viewModel = makeViewModel(exporter: exporter)
        
        #expect(viewModel.prepareModel() == false)
        #expect(viewModel.showExportFailureAlert == true)
    }
    
    @Test("장소명 인라인 편집을 마치면 값이 반영되고 오버레이가 닫힌다")
    func inlineCommentEditing() {
        let viewModel = makeViewModel()
        
        viewModel.beginEditingComment()
        #expect(viewModel.isEditingComment == true)
        
        viewModel.endEditingComment(with: "작업실")
        
        #expect(viewModel.comment == "작업실")
        #expect(viewModel.isEditingComment == false)
    }
    
    @Test("날짜 토글은 켜짐·꺼짐을 오간다")
    func togglesDate() {
        let viewModel = makeViewModel()
        
        viewModel.toggleDate()
        #expect(viewModel.showsDate == false)
        
        viewModel.toggleDate()
        #expect(viewModel.showsDate == true)
    }
    
    @Test("각도 리셋은 3D 뷰에 전달할 신호를 올린다")
    func resetsModelAngle() {
        let viewModel = makeViewModel()
        let before = viewModel.modelResetToken
        
        viewModel.resetModelAngle()
        
        #expect(viewModel.modelResetToken == before + 1)
    }
    
    @Test("편집 캔버스로 들어갈 때 날짜와 위치가 확정된다")
    func finishScanningFixesDateAndLocation() {
        let locationService = FakeLocationService(
            lastKnownLocation: CLLocationCoordinate2D(latitude: 36.0190, longitude: 129.3435)
        )
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(locationService: locationService, repository: repository)
        
        viewModel.finishScanning()
        
        //yyyy.MM.dd 형식으로 날짜가 채워졌는지 확인
        #expect(viewModel.dateText.wholeMatch(of: /\d{4}\.\d{2}\.\d{2}/) != nil)
        
        viewModel.saveSpaceData()
        #expect(repository.spaces.first?.latitude == 36.0190)
    }
    
    @Test("USDZ를 내보낸 뒤에는 저장에 성공하고 usdz 카드로 기록된다")
    func saveSucceedsAfterExport() {
        let repository = InMemorySpaceRepository()
        let locationService = FakeLocationService(
            lastKnownLocation: CLLocationCoordinate2D(latitude: 36.0190, longitude: 129.3435)
        )
        let exporter = FakeRoomExporter(
            result: makeExportedRoom(fileName: "room.usdz", furniture: [makeFurniture(category: "sofa")], roomType: .livingRoom)
        )
        let viewModel = makeViewModel(locationService: locationService, repository: repository, exporter: exporter)
        viewModel.finishScanning()
        viewModel.endEditingComment(with: "작업실")
        viewModel.toggleDate()
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedSuccessAlert == true)
        #expect(viewModel.showSavedFailureAlert == false)
        
        let saved = repository.spaces.first
        #expect(saved?.comment == "작업실")
        #expect(saved?.kind == .usdz)
        #expect(saved?.modelFileName == "room.usdz")
        #expect(saved?.latitude == 36.0190)
        #expect(saved?.roomType == .livingRoom)
        #expect(saved?.furniture.first?.category == "sofa")
        //신규 스캔은 예외 없이 업로드 대기 상태로 저장된다 (D-06)
        #expect(saved?.sync == .pending)
        #expect(saved?.isPublic == false)
        //편집 캔버스에서 날짜를 껐으면 카드에도 반영된다
        #expect(saved?.showsDate == false)
    }
    
    @Test("내보낸 모델이 없으면 저장하지 않고 실패 알림을 보여준다")
    func saveFailsWithoutExportedModel() {
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(repository: repository)
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedFailureAlert == true)
        #expect(repository.spaces.isEmpty)
    }
    
    @Test("저장소가 실패를 리턴하면 실패 알림을 보여준다")
    func saveFailsWhenRepositoryFails() {
        let repository = InMemorySpaceRepository()
        repository.shouldFailToSave = true
        let viewModel = makeViewModel(repository: repository)
        viewModel.prepareModel()
        
        viewModel.saveSpaceData()
        
        #expect(viewModel.showSavedFailureAlert == true)
        #expect(viewModel.showSavedSuccessAlert == false)
    }
    
    @Test("저장 후 상태를 되돌리면 scan 단계로 돌아간다")
    func resetAfterSaveReturnsToScan() {
        let viewModel = makeViewModel()
        viewModel.finishScanning()
        
        viewModel.resetAfterSave()
        
        #expect(viewModel.currentStep == .capture)
        #expect(viewModel.doneScanning == false)
    }
}
