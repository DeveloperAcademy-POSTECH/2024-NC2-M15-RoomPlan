//
//  RoomScanService.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import RoomPlan

//방 캡쳐 세션을 제어하고 결과를 보관하는 역할
protocol RoomScanning: AnyObject {
    //캡쳐가 완료된 스캔 결과. 아직 끝나지 않았으면 nil
    var capturedRoom: CapturedRoom? { get }
    func startSession()
    func stopSession()
}

//RoomPlan이 제공하는 캡쳐 뷰를 UI 계층에 전달하는 역할
protocol RoomCaptureViewProviding: AnyObject {
    var captureView: RoomCaptureView { get }
}

//스캔 화면이 필요로 하는 두 역할을 함께 만족하는 타입
typealias RoomScanner = RoomScanning & RoomCaptureViewProviding

//방 캡쳐를 담당하는 클래스
@Observable
final class RoomPlanManager: RoomCaptureViewDelegate, RoomScanning, RoomCaptureViewProviding {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    var captureView: RoomCaptureView
    //스캔 결과를 USDZ로 내보내야 하므로 외부에서 읽을 수 있게 공개한다
    private(set) var capturedRoom: CapturedRoom?
    private var sessionConfig: RoomCaptureSession.Configuration
    
    init() {
        captureView = RoomCaptureView(frame: .zero)
        sessionConfig = RoomCaptureSession.Configuration()
        captureView.delegate = self
    }
    
    //캡쳐가 완료되었는지 아닌지에 대해서 Bool 값을 리턴하는 함수
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    //캡쳐가 완료된 결과를 저장하는 함수
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        capturedRoom = processedResult
    }
    
    //캡쳐를 시작하는 함수
    func startSession() {
        capturedRoom = nil
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    //캡쳐를 종료하는 함수
    func stopSession() {
        captureView.captureSession.stop()
    }
}
