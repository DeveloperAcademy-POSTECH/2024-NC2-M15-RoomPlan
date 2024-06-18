//
//  RoomController.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import RoomPlan

class RoomController: RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    static var instance = RoomController()
    
    var captureView: RoomCaptureView
    var sessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    var finalResult: CapturedRoom?
    
    init() {
        captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = self
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        finalResult = processedResult
    }
    
    func startSession() {
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    func stopSession() {
        captureView.captureSession.stop()
    }
}

struct RoomCaptureViewRepresentable : UIViewRepresentable {
    func makeUIView(context: Context) -> RoomCaptureView {
        RoomController.instance.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
