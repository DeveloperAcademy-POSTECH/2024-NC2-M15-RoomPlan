//
//  ScanFlowView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//공간을 캡쳐하고 공간 카드를 만들기까지의 단계를 연결하는 컨테이너 뷰
struct ScanFlowView: View {
    //스캔 중에는 드로어 제스처를 꺼야 하므로 상태를 바깥으로 알린다
    let onScanActiveChange: (Bool) -> Void
    //저장이 끝나 화면을 벗어날 때 호출된다
    let onFinish: () -> Void
    
    @State private var viewModel: ScanFlowViewModel
    @State private var scanner: any RoomScanner
    
    init(
        container: AppContainer,
        onScanActiveChange: @escaping (Bool) -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.onScanActiveChange = onScanActiveChange
        self.onFinish = onFinish
        
        let scanner = container.makeRoomScanner()
        _scanner = State(initialValue: scanner)
        _viewModel = State(initialValue: ScanFlowViewModel(
            scanner: scanner,
            locationService: container.locationService,
            spaceRepository: container.spaceRepository,
            roomExporter: container.makeRoomExporter(scanner: scanner)
        ))
    }
    
    var body: some View {
        Group {
            switch viewModel.currentPage {
            case .scan:
                ScanCaptureView(viewModel: viewModel, scanner: scanner)
            case .scanResult:
                ScanResultView(viewModel: viewModel)
            case .addInfo:
                ScanAddInfoView(viewModel: viewModel)
            case .finalResult:
                ScanFinalResultView(viewModel: viewModel, onFinish: onFinish)
            }
        }
        //캡쳐 화면에서는 드로어 제스처를 비활성화한다
        .onChange(of: viewModel.currentPage, initial: true) {
            onScanActiveChange(viewModel.currentPage == .scan)
        }
        .onDisappear {
            onScanActiveChange(false)
        }
    }
}
