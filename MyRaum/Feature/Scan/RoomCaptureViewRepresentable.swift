//
//  RoomCaptureViewRepresentable.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import RoomPlan

//UIKit으로 작성된 RoomPlan 뷰를 SwiftUI에서 보여지도록 UIViewRepresentable 프로토콜을 사용한 뷰
struct RoomCaptureViewRepresentable: UIViewRepresentable {
    let provider: any RoomCaptureViewProviding
    
    //뷰를 생성하고 초기화하는 함수
    func makeUIView(context: Context) -> RoomCaptureView {
        provider.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
