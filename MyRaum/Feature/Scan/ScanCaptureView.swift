//
//  ScanCaptureView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import PhotosUI

//방 캡쳐 화면 & 캡쳐 결과 확인 화면
struct ScanCaptureView: View {
    @Bindable var viewModel: ScanFlowViewModel
    let scanner: any RoomScanner
    
    var body: some View {
        VStack {
            if viewModel.doneScanning == true {
                Text("3D 모델의 각도를 조절한 후\n배경을 추가하세요.")
                    .bold()
                    .multilineTextAlignment(.center)
            }
            
            RoomCaptureViewRepresentable(provider: scanner)
                .onAppear(perform: {
                    viewModel.startScanning()
                })
                .ignoresSafeArea(.all)
            
            if viewModel.doneScanning == false {
                TextButtonCapsule(text: "스캔 끝내기", color: .gray) {
                    viewModel.finishScanning()
                }
            } else {
                HStack(spacing: 16) {
                    TextButtonRoundedRectangle(text: "다시 스캔하기") {
                        viewModel.restartScanning()
                    }
                    
                    PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.grayButtonStroke)
                            .frame(height: 60)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .foregroundStyle(Color.grayButton)
                                
                                Text("배경 추가하기")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white)
                            }
                    }
                    .onChange(of: viewModel.selectedItem) {
                        Task {
                            await viewModel.captureModelAndLoadBackground()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
