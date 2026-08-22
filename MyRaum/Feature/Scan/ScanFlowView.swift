//
//  ScanFlowView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//공간을 캡쳐하고 공간 카드를 만들기까지의 단계를 연결하는 컨테이너 뷰
struct ScanFlowView: View {
    @State private var viewModel: ScanFlowViewModel
    @State private var scanner: any RoomScanner
    
    init(container: AppContainer) {
        let scanner = container.makeRoomScanner()
        _scanner = State(initialValue: scanner)
        _viewModel = State(initialValue: ScanFlowViewModel(
            scanner: scanner,
            modelCapturer: container.makeModelCapturer(),
            locationService: container.locationService,
            spaceRepository: container.spaceRepository
        ))
    }
    
    var body: some View {
        switch viewModel.currentPage {
        case .scan:
            ScanCaptureView(viewModel: viewModel, scanner: scanner)
        case .scanResult:
            ScanResultView(viewModel: viewModel)
        case .addInfo:
            ScanAddInfoView(viewModel: viewModel)
        case .finalResult:
            ScanFinalResultView(viewModel: viewModel)
        }
    }
}
