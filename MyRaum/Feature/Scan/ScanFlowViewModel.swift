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
    private let modelFileStore: any ModelFileStoring
    
    var currentStep: ScanStep = .capture
    var doneScanning: Bool = false
    var selectedItem: PhotosPickerItem?
    var background: UIImage?
    var comment: String = ""
    //편집 캔버스의 날짜 토글
    var showsDate: Bool = true
    //장소명 인라인 편집 중인지
    var isEditingComment: Bool = false
    //값이 바뀌면 3D 모델의 각도가 초기화된다
    var modelResetToken: Int = 0
    
    var showSavedSuccessAlert: Bool = false
    var showSavedFailureAlert: Bool = false
    var showExportFailureAlert: Bool = false
    var isPreparingModel: Bool = false
    
    //카드에 보여줄 3D 모델의 미리보기 이미지 (USDZ 썸네일)
    var thumbnail: UIImage?
    //인식된 가구·면적·방 종류
    private(set) var metrics: RoomMetrics?
    
    private let spaceID = UUID()
    private(set) var modelFileName: String?
    private var date: Date = .now
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    
    init(
        scanner: any RoomScanning,
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository,
        roomExporter: any RoomExporting,
        modelFileStore: any ModelFileStoring
    ) {
        self.scanner = scanner
        self.locationService = locationService
        self.spaceRepository = spaceRepository
        self.roomExporter = roomExporter
        self.modelFileStore = modelFileStore
    }
    
    //편집 캔버스에서 보여줄 USDZ 경로
    var modelURL: URL? {
        guard let modelFileName else { return nil }
        return modelFileStore.url(forFileName: modelFileName)
    }
    
    //신뢰도가 낮은 오브젝트가 있으면 더 스캔하도록 안내하기 위한 값
    var lowConfidenceCount: Int {
        metrics?.lowConfidenceCount ?? 0
    }
    
    //카드에 표시할 날짜 문자열
    var dateText: String {
        date.spaceCardFormatted
    }
    
    //캡쳐를 시작할 때 위치 정보 권한을 승인할 것인지 확인
    func startScanning() {
        scanner.startSession()
        locationService.checkLocationAuthorization()
    }
    
    //스캔을 끝내고 편집 캔버스로 넘어가는 함수
    //화면 전환 없이 하나의 캔버스에서 마무리하도록 여기서 USDZ까지 만들어 둔다
    func finishScanning() {
        scanner.stopSession()
        doneScanning = true
        
        guard prepareModel() else { return }
        
        //편집 캔버스에 들어갈 때 날짜·위치를 확정한다
        date = .now
        if let coordinate = locationService.lastKnownLocation {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        }
        
        currentStep = .edit
    }
    
    //처음부터 다시 스캔
    func restartScanning() {
        currentStep = .capture
        doneScanning = false
        modelFileName = nil
        thumbnail = nil
        metrics = nil
        scanner.startSession()
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
    
    //장소명 인라인 편집을 시작·종료하는 함수
    func beginEditingComment() {
        isEditingComment = true
    }
    
    func endEditingComment(with newComment: String) {
        comment = newComment
        isEditingComment = false
    }
    
    //날짜 노출 여부를 뒤집는 함수
    func toggleDate() {
        showsDate.toggle()
    }
    
    //3D 모델의 각도를 초기 상태로 되돌리는 함수
    func resetModelAngle() {
        modelResetToken += 1
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
            showsDate: showsDate,
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
        currentStep = .capture
    }
}
