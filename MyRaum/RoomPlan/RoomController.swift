//
//  RoomController.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import RoomPlan

//방 캡쳐를 담당하는 클래스
class RoomController: RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    //코드의 다른 부분에서 접근 가능하도록 싱글턴으로 인스턴스 생성
    static var instance = RoomController()
    
    var captureView: RoomCaptureView
    var sessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    var finalResult: CapturedRoom?
    
    init() {
        captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = self
    }
    
    //캡쳐가 완료되었는지 아닌지에 대해서 Bool 값을 리턴하는 함수
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    //캡쳐가 완료된 결과를 finalResult에 저장하는 함수
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        finalResult = processedResult
    }
    
    //캡쳐를 시작하는 함수
    func startSession() {
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    //캡쳐를 종료하는 함수
    func stopSession() {
        captureView.captureSession.stop()
    }
}

//UIKit으로 작성된 RoomPlan 뷰를 SwiftUI에서 보여지도록 UIViewRepresentable 프로토콜을 사용한 뷰
struct RoomCaptureViewRepresentable : UIViewRepresentable {
    //뷰를 생성하고 초기화하는 함수
    func makeUIView(context: Context) -> RoomCaptureView {
        RoomController.instance.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
