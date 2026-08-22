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
    
    private var spaceID = UUID()
    private(set) var modelFileName: String?
    private var date: Date = .now
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    
    //MultiRoom — 같은 구조에 이어 붙인 방들 (D-04, 8.1)
    private(set) var structureID: UUID?
    private var savedRooms: [PendingRoom] = []
    
    //구조에 담긴 방의 개수 (편집 중인 방 포함)
    var roomCountInStructure: Int {
        savedRooms.count + 1
    }
    
    //편집 중인 방을 잠시 담아 두는 값
    private struct PendingRoom {
        let id: UUID
        let modelFileName: String
        let comment: String
        let background: Data?
        let thumbnail: Data?
        let showsDate: Bool
        let metrics: RoomMetrics?
    }
    
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
    //구조에 담아 둔 방이 있으면 모두 함께 저장한다 (8.1)
    func saveSpaceData() {
        //USDZ 파일이 없으면 저장할 3D 모델이 없는 것이므로 저장하지 않는다
        guard let modelFileName else {
            showSavedFailureAlert = true
            return
        }
        
        let lastRoom = PendingRoom(
            id: spaceID,
            modelFileName: modelFileName,
            comment: comment,
            background: background?.pngData(),
            thumbnail: thumbnail?.pngData(),
            showsDate: showsDate,
            metrics: metrics
        )
        let rooms = savedRooms + [lastRoom]
        
        let saved = rooms.enumerated().allSatisfy { order, room in
            spaceRepository.save(makeSpaceData(from: room, order: order, roomCount: rooms.count))
        }
        
        guard saved else {
            showSavedFailureAlert = true
            return
        }
        
        showSavedSuccessAlert = true
        
        //방이 여러 개면 CapturedStructure로 병합한 "집 전체" 모델을 덧붙인다
        //병합에 실패해도 각 방은 이미 저장되어 있으므로 저장 자체는 성공으로 둔다
        if let structureID, rooms.count >= 2 {
            mergeStructure(structureID: structureID, representativeID: rooms[0].id)
        }
    }
    
    //담아 둔 방 하나를 저장 가능한 형태로 만드는 함수
    private func makeSpaceData(from room: PendingRoom, order: Int, roomCount: Int) -> SpaceData {
        SpaceData(
            id: room.id,
            createdAt: date,
            comment: room.comment,
            latitude: latitude,
            longitude: longitude,
            storageKind: .usdz,
            background: room.background,
            showsDate: room.showsDate,
            modelFileName: room.modelFileName,
            thumbnail: room.thumbnail,
            //방이 하나뿐이면 구조로 묶지 않는다
            structureID: roomCount >= 2 ? structureID : nil,
            structureOrder: roomCount >= 2 ? order : nil,
            furnitureJSON: room.metrics?.furniture.encodedJSON(),
            floorAreaSqM: room.metrics?.floorAreaSqM,
            roomTypeGuess: room.metrics?.roomType.rawValue,
            //2.0에서 스캔한 공간은 전부 서버에 올린다 (D-06)
            syncState: .pending
        )
    }
    
    //병합된 구조 모델을 만들어 대표 방에 붙이는 함수
    private func mergeStructure(structureID: UUID, representativeID: UUID) {
        Task {
            guard let fileName = await roomExporter.exportMergedStructure(id: structureID) else { return }
            
            let representative = spaceRepository.fetchAll().first { $0.id == representativeID }
            representative?.structureModelFileName = fileName
            spaceRepository.saveChanges()
        }
    }
    
    //현재 방을 구조에 담고 다음 방 스캔으로 넘어가는 함수 (8.1 "방 추가하기")
    func addAnotherRoom() {
        guard let modelFileName else {
            showSavedFailureAlert = true
            return
        }
        
        //첫 "방 추가하기" 시점에 구조가 만들어진다
        if structureID == nil {
            structureID = UUID()
        }
        
        savedRooms.append(PendingRoom(
            id: spaceID,
            modelFileName: modelFileName,
            comment: comment,
            background: background?.pngData(),
            thumbnail: thumbnail?.pngData(),
            showsDate: showsDate,
            metrics: metrics
        ))
        
        scanner.keepCurrentRoomForStructure()
        
        //다음 방은 새 식별자로 처음부터 다시 입력받는다
        spaceID = UUID()
        self.modelFileName = nil
        thumbnail = nil
        self.metrics = nil
        comment = ""
        background = nil
        selectedItem = nil
        showsDate = true
        
        currentStep = .capture
        doneScanning = false
        scanner.startSession()
    }
    
    //저장 알림을 닫고 화면을 벗어나기 전 상태를 되돌리는 함수
    func resetAfterSave() {
        doneScanning = false
        currentStep = .capture
    }
}
