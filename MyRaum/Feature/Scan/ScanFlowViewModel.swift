//
//  ScanFlowViewModel.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import PhotosUI

//스캔부터 저장까지의 단계 전환과 입력값을 소유하는 뷰모델
@Observable
@MainActor
final class ScanFlowViewModel {
    private let scanner: any RoomScanning
    private let locationService: any LocationProviding
    private let spaceRepository: any SpaceRepository
    private let roomExporter: any RoomExporting
    
    var currentPage: RoomPlanPage = .scan
    var doneScanning: Bool = false
    var selectedItem: PhotosPickerItem?
    var background: UIImage?
    var comment: String = ""
    var dateString: String?
    var showCommentPopup: Bool = false
    var showSavedSuccessAlert: Bool = false
    var showSavedFailureAlert: Bool = false
    var showExportFailureAlert: Bool = false
    var isPreparingModel: Bool = false
    
    //카드에 보여줄 3D 모델의 미리보기 이미지 (USDZ 썸네일)
    var thumbnail: UIImage?
    //인식된 가구·면적·방 종류
    private(set) var metrics: RoomMetrics?
    
    private let spaceID = UUID()
    private var modelFileName: String?
    private var date: Date = .now
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    
    init(
        scanner: any RoomScanning,
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository,
        roomExporter: any RoomExporting
    ) {
        self.scanner = scanner
        self.locationService = locationService
        self.spaceRepository = spaceRepository
        self.roomExporter = roomExporter
    }
    
    //신뢰도가 낮은 오브젝트가 있으면 더 스캔하도록 안내하기 위한 값
    var lowConfidenceCount: Int {
        metrics?.lowConfidenceCount ?? 0
    }
    
    //캡쳐를 시작할 때 위치 정보 권한을 승인할 것인지 확인
    func startScanning() {
        scanner.startSession()
        locationService.checkLocationAuthorization()
    }
    
    //스캔을 끝내고 결과를 확인하는 상태로 전환
    func finishScanning() {
        scanner.stopSession()
        doneScanning = true
    }
    
    //처음부터 다시 스캔
    func restartScanning() {
        currentPage = .scan
        doneScanning = false
        modelFileName = nil
        thumbnail = nil
        metrics = nil
        scanner.startSession()
    }
    
    //배경 이미지를 선택하면 스캔 결과를 USDZ로 내보내고 썸네일을 만든 뒤 결과 화면으로 이동
    func prepareModelAndLoadBackground() async {
        await loadBackground()
        
        if prepareModel() {
            currentPage = .scanResult
        }
    }
    
    //스캔 결과를 USDZ 파일로 저장하고 썸네일을 렌더링하는 함수
    //성공하면 true를 리턴
    @discardableResult
    func prepareModel() -> Bool {
        //이미 내보낸 모델이 있으면 다시 만들지 않는다
        if modelFileName != nil { return true }
        
        isPreparingModel = true
        defer { isPreparingModel = false }
        
        do {
            let exported = try roomExporter.exportCurrentScan(id: spaceID)
            modelFileName = exported.fileName
            thumbnail = exported.thumbnailData.flatMap { UIImage(data: $0) }
            metrics = exported.metrics
            
            return true
        } catch {
            print("Failed to export USDZ: \(error)")
            showExportFailureAlert = true
            return false
        }
    }
    
    //선택한 사진을 배경 이미지로 불러오는 함수
    func loadBackground() async {
        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
            background = UIImage(data: data)
        } else {
            print("Failed to load the image")
        }
    }
    
    //장소 입력 팝업에서 입력을 완료했을 때
    func confirmComment(_ newComment: String) {
        comment = newComment
        currentPage = .addInfo
        showCommentPopup = false
    }
    
    //미리보기 버튼을 선택할때 현재의 날짜 정보와 위치 정보 입력
    func moveToFinalResult() {
        date = .now
        dateString = date.spaceCardFormatted
        
        if let coordinate = locationService.lastKnownLocation {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        }
        
        currentPage = .finalResult
    }
    
    //입력된 정보로 공간 카드를 저장하는 함수
    func saveSpaceData() {
        //USDZ 파일이 없으면 저장할 3D 모델이 없는 것이므로 저장하지 않는다
        guard let modelFileName else {
            showSavedFailureAlert = true
            return
        }
        
        let newSpace = SpaceData(
            id: spaceID,
            createdAt: date,
            comment: comment,
            latitude: latitude,
            longitude: longitude,
            storageKind: .usdz,
            background: background?.pngData(),
            modelFileName: modelFileName,
            thumbnail: thumbnail?.pngData(),
            furnitureJSON: metrics?.furniture.encodedJSON(),
            floorAreaSqM: metrics?.floorAreaSqM,
            roomTypeGuess: metrics?.roomType.rawValue,
            //2.0에서 스캔한 공간은 전부 서버에 올린다 (D-06). 업로드는 Phase 6에서 붙인다
            syncState: .pending
        )
        
        if spaceRepository.save(newSpace) {
            showSavedSuccessAlert = true
        } else {
            showSavedFailureAlert = true
        }
    }
    
    //저장 알림을 닫고 화면을 벗어나기 전 상태를 되돌리는 함수
    func resetAfterSave() {
        doneScanning = false
        currentPage = .scan
    }
}
