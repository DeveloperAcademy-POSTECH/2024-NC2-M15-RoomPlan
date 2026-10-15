//
//  RoomPlanManager.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import RoomPlan

//방 캡쳐를 담당하는 클래스
//RoomCaptureView가 벽, 문, 창문과 함께 가구(소파, 침대, 테이블 등)도 인식함
@Observable
final class RoomPlanManager: RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }

    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }

    var captureView: RoomCaptureView
    private var sessionConfig: RoomCaptureSession.Configuration
    //스캔 결과 처리가 끝나면 호출됨 (실패한 경우 nil)
    @ObservationIgnored var onCaptureCompleted: ((CapturedRoom?) -> Void)?

    init() {
        captureView = RoomCaptureView(frame: .zero)
        sessionConfig = RoomCaptureSession.Configuration()
        captureView.delegate = self
    }

    //스캔 데이터를 3D 모델로 처리할지 결정하는 함수 - 스캔 중 오류가 있었으면 처리하지 않음
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        if let error {
            print("Capture failed: \(error.localizedDescription)")
            onCaptureCompleted?(nil)
            return false
        }
        return true
    }

    //처리가 완료된 결과를 전달하는 함수
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        if let error {
            print("Processing failed: \(error.localizedDescription)")
            onCaptureCompleted?(nil)
            return
        }
        onCaptureCompleted?(processedResult)
    }

    //캡쳐를 시작하는 함수
    func startSession() {
        captureView.captureSession.run(configuration: sessionConfig)
    }

    //캡쳐를 종료하는 함수 - 종료 후 결과 처리가 시작됨
    func stopSession() {
        captureView.captureSession.stop()
    }
}

//UIKit으로 작성된 RoomPlan 뷰를 SwiftUI에서 보여지도록 UIViewRepresentable 프로토콜을 사용한 뷰
struct RoomCaptureViewRepresentable : UIViewRepresentable {
    let manager: RoomPlanManager

    //뷰를 생성하고 초기화하는 함수
    func makeUIView(context: Context) -> RoomCaptureView {
        manager.captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {

    }
}
