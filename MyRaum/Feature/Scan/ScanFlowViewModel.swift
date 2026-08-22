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
    private let modelCapturer: any ModelCapturing
    private let locationService: any LocationProviding
    private let spaceRepository: any SpaceRepository
    
    var currentPage: RoomPlanPage = .scan
    var doneScanning: Bool = false
    var selectedItem: PhotosPickerItem?
    var model: UIImage?
    var background: UIImage?
    var comment: String = ""
    var dateString: String?
    var showCommentPopup: Bool = false
    var showSavedSuccessAlert: Bool = false
    var showSavedFailureAlert: Bool = false
    
    private var date: Date = .now
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    
    init(
        scanner: any RoomScanning,
        modelCapturer: any ModelCapturing,
        locationService: any LocationProviding,
        spaceRepository: any SpaceRepository
    ) {
        self.scanner = scanner
        self.modelCapturer = modelCapturer
        self.locationService = locationService
        self.spaceRepository = spaceRepository
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
        scanner.startSession()
    }
    
    //배경 이미지를 선택할때 3D 모델은 화면 캡쳐 및 배경 제거를 통해 모델만 존재하는 이미지로 변환
    func captureModelAndLoadBackground() async {
        //화면 캡쳐
        if let capturedView = modelCapturer.captureScreen() {
            //배경 제거
            Task {
                model = await modelCapturer.createSticker(image: capturedView)
            }
        }
        
        await loadBackground()
        
        currentPage = .scanResult
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
        let savedDate = date.spaceCardFormatted
        
        //PNG 변환에 실패하면 저장하지 않고 실패 알림을 보여줌
        guard let model, let background,
              let modelData = model.pngData(),
              let backgroundData = background.pngData() else {
            showSavedFailureAlert = true
            return
        }
        
        let newSpace = SpaceData(
            id: UUID(),
            date: savedDate,
            comment: comment,
            model: modelData,
            background: backgroundData,
            latitude: latitude,
            longitude: longitude
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
