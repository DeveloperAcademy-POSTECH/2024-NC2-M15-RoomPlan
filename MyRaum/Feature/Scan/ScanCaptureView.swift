//
//  ScanCaptureView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//방 캡쳐 화면 — RoomPlan 캡쳐 뷰 위에 커스텀 코칭 오버레이를 올린다
struct ScanCaptureView: View {
    @Bindable var viewModel: ScanFlowViewModel
    let scanner: any RoomScanner
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable(provider: scanner)
                .ignoresSafeArea(.all)
                .onAppear(perform: {
                    viewModel.startScanning()
                })
            
            VStack {
                HStack {
                    CloseScanButton(action: onClose)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ScanStepIndicator(step: .capture)
                    .padding(.top, 12)
                
                coachingOverlay
                
                Spacer()
                
                if viewModel.isPreparingModel {
                    ProgressView()
                        .tint(.white)
                        .padding(.bottom, 20)
                }
                
                TextButtonCapsule(text: "스캔 끝내기", color: .gray) {
                    viewModel.finishScanning()
                }
                .padding(.bottom, 40)
            }
        }
        .alert("3D 모델을 저장하지 못했습니다.", isPresented: $viewModel.showExportFailureAlert) {
            Button {
            } label: {
                Text("확인")
            }
        }
    }
}

private extension ScanCaptureView {
    //RoomPlan 기본 안내 위에 앱의 문구를 얹은 코칭 오버레이
    var coachingOverlay: some View {
        Text("공간을 천천히 둘러보며 벽과 가구를 비춰주세요.")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule().foregroundStyle(Color.black.opacity(0.55))
            }
            .padding(.top, 16)
    }
}
