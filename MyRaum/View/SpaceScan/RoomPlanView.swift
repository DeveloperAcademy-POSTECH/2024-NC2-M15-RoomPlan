//
//  RoomPlanView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData
import RoomPlan

//공간을 스캔하고 스토리처럼 꾸며서 공간 카드를 만드는 화면
//스캔 → 3D 모델 생성 → 꾸미기(StoryEditorView) 순서로 진행
struct RoomPlanView: View {
    private enum Phase {
        case scanning
        case processing
        case editing(ScannedRoom)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettingsManager.self) private var appSettingsManager

    @State private var roomPlanManager = RoomPlanManager()
    @State private var locationManager = LocationManager()
    @State private var phase: Phase = .scanning
    @State private var showScanFailedAlert: Bool = false

    var body: some View {
        Group {
            switch phase {
            case .scanning, .processing:
                scanView
            case .editing(let room):
                StoryEditorView(
                    room: room,
                    //앱 설정에서 위치 정보 저장을 끄면 위치 없이 저장
                    locationManager: appSettingsManager.savesLocation ? locationManager : nil,
                    onRescan: {
                        //편집 화면이 사라지고 스캔 화면이 다시 나타나면 onAppear에서 스캔이 시작됨
                        phase = .scanning
                    },
                    onExit: {
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            roomPlanManager.onCaptureCompleted = { capturedRoom in
                handleCaptureCompleted(capturedRoom)
            }
        }
        .onDisappear {
            if case .scanning = phase {
                roomPlanManager.stopSession()
            }
            locationManager.stopUpdatingLocation()
        }
        .alert("스캔에 실패했습니다.", isPresented: $showScanFailedAlert) {
            Button {
                phase = .scanning
                roomPlanManager.startSession()
            } label: {
                Text("다시 스캔하기")
            }
        } message: {
            Text("천천히 움직이며 다시 스캔해주세요.")
        }
    }
}

private extension RoomPlanView {
    //전체 화면으로 열리므로 스캔 중에 나갈 수 있는 닫기 버튼
    var closeButton: some View {
        Button {
            HapticManager.tap()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
        .accessibilityLabel(Text("닫기"))
        .padding(.leading, 16)
    }
    
    var isProcessing: Bool {
        if case .processing = phase {
            return true
        }
        return false
    }

    // 공간 스캔 화면 - RoomPlan이 벽, 문, 창문, 가구를 인식해서 실시간으로 보여줌
    var scanView: some View {
        ZStack {
            RoomCaptureViewRepresentable(manager: roomPlanManager)
                .ignoresSafeArea(.all)
                .onAppear(perform: {
                    roomPlanManager.startSession()

                    //캡쳐를 시작할 때 위치 정보 권한을 승인할 것인지 확인 (위치 정보 저장을 켰을 때만)
                    if appSettingsManager.savesLocation {
                        locationManager.checkLocationAuthorization()
                    }
                })

            VStack {
                //닫기 버튼은 왼쪽, 안내 문구는 가운데
                ZStack {
                    HStack {
                        closeButton
                        
                        Spacer()
                    }
                    
                    if !isProcessing {
                        Text("벽과 가구를 천천히 비추며 공간을 스캔하세요.")
                            .font(.footnote)
                            .bold()
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                    }
                }

                Spacer()

                if isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.white)

                        Text("3D 모델을 만드는 중입니다...")
                            .bold()
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                } else {
                    TextButtonCapsule(text: "스캔 끝내기", color: .gray) {
                        phase = .processing
                        roomPlanManager.stopSession()
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }

    //RoomPlan의 처리가 끝나면 USDZ로 내보낸 뒤 꾸미기 화면으로 이동
    func handleCaptureCompleted(_ capturedRoom: CapturedRoom?) {
        guard isProcessing else { return }
        guard let capturedRoom else {
            showScanFailedAlert = true
            return
        }

        Task {
            do {
                let room = try await ScannedRoom.make(from: capturedRoom)
                HapticManager.notify(.success)
                phase = .editing(room)
            } catch {
                print("Failed to export room: \(error.localizedDescription)")
                HapticManager.notify(.error)
                showScanFailedAlert = true
            }
        }
    }
}

#Preview {
    RoomPlanView()
        .modelContainer(for: SpaceRecord.self, inMemory: true)
        .environment(AppSettingsManager())
}
