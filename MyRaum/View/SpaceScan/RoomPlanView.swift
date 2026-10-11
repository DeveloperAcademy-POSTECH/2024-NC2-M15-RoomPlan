//
//  RoomPlanView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData
import PhotosUI

//공간을 캡쳐하고 공간 카드를 만들기까지의 프로세스들을 구현한 뷰
struct RoomPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var roomPlanManager = RoomPlanManager()
    @State private var locationManager = LocationManager()
    @State private var draft = SpaceDraft()
    @State private var currentPage: RoomPlanPage = .scan
    @State private var doneScanning: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCommentPopup: Bool = false
    @State private var showSavedSuccessAlert: Bool = false
    @State private var showSavedFailureAlert: Bool = false

    private let modelCaptureManager = ModelCaptureManager()

    var body: some View {
        ZStack {
            switch currentPage {
            case .scan:
                scanView
            case .scanResult:
                scanResultView
            case .addInfo:
                addInfoView
            case .finalResult:
                finalResultView
            }

            if showCommentPopup {
                commentPopup
            }
        }
        .onDisappear {
            if !doneScanning {
                roomPlanManager.stopSession()
            }
            locationManager.stopUpdatingLocation()
        }
    }
}

private extension RoomPlanView {
    // 방 캡쳐 화면 & 캡쳐 결과 확인 화면
    var scanView: some View {
        VStack {
            if doneScanning == true {
                Text("3D 모델의 각도를 조절한 후\n배경을 추가하세요.")
                    .bold()
                    .multilineTextAlignment(.center)
            }

            RoomCaptureViewRepresentable(manager: roomPlanManager)
                .onAppear(perform: {
                    roomPlanManager.startSession()

                    //캡쳐를 시작할 때 위치 정보 권한을 승인할 것인지 확인
                    locationManager.checkLocationAuthorization()
                })
                .ignoresSafeArea(.all)

            if doneScanning == false {
                TextButtonCapsule(text: "스캔 끝내기", color: .gray) {
                    roomPlanManager.stopSession()
                    doneScanning = true
                }
            } else {
                HStack(spacing: 16) {
                    TextButtonRoundedRectangle(text: "다시 스캔하기") {
                        doneScanning = false
                        roomPlanManager.startSession()
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        RoundedRectangleButtonLabel(text: "배경 추가하기")
                    }
                    .onChange(of: selectedItem) {
                        Task {
                            //배경 이미지를 선택할때 3D 모델은 화면 캡쳐 및 배경 제거를 통해 모델만 존재하는 이미지로 변환
                            if let capturedView = modelCaptureManager.captureScreen() {
                                Task {
                                    draft.model = await modelCaptureManager.createSticker(image: capturedView)
                                }
                            }

                            await loadBackground()
                            currentPage = .scanResult
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // 방 모델 이미지 + 배경 이미지 화면
    var scanResultView: some View {
        cardStepView(title: "장소를 입력하세요.") {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                RoundedRectangleButtonLabel(text: "배경 수정하기")
            }
            .onChange(of: selectedItem) {
                Task {
                    await loadBackground()
                }
            }

            TextButtonRoundedRectangle(text: "장소 입력하기") {
                showCommentPopup = true
            }
        }
    }

    // 방 모델 이미지 + 배경 이미지 + 장소명 화면
    var addInfoView: some View {
        cardStepView(title: "결과물을 확인하세요.") {
            TextButtonRoundedRectangle(text: "장소 수정하기") {
                showCommentPopup = true
            }

            TextButtonRoundedRectangle(text: "미리보기") {
                //미리보기 버튼을 선택할때 현재의 날짜, 위치 정보 입력
                draft.date = .now
                draft.coordinate = locationManager.lastKnownLocation
                currentPage = .finalResult
            }
        }
    }

    // 최종 결과 확인 화면
    var finalResultView: some View {
        cardStepView(title: "결과물을 저장해보세요.") {
            TextButtonRoundedRectangle(text: "저장") {
                saveSpaceData()
            }
        }
        .alert("저장되었습니다.", isPresented: $showSavedSuccessAlert) {
            Button {
                dismiss()
            } label: {
                Text("확인")
            }
        }
        .alert("저장하지 못했습니다.", isPresented: $showSavedFailureAlert) {
            Button {
                dismiss()
            } label: {
                Text("확인")
            }
        }
    }

    // 장소 입력 팝업
    var commentPopup: some View {
        ZStack {
            Color.black
                .opacity(0.5)
                .ignoresSafeArea()

            CommentPopupView(initialComment: draft.comment) { comment in
                draft.comment = comment
                currentPage = .addInfo
                showCommentPopup = false
            }
        }
    }

    // 스캔 이후 단계들의 공통 레이아웃 - 안내 문구 + 카드 미리보기 + 하단 버튼
    func cardStepView<Buttons: View>(title: LocalizedStringKey, @ViewBuilder buttons: () -> Buttons) -> some View {
        VStack {
            Text(title)
                .bold()
                .padding()

            SpaceCardFrontView(
                model: draft.model,
                background: draft.background,
                comment: draft.comment,
                date: draft.dateString
            )

            Spacer()

            HStack(spacing: 16) {
                buttons()
            }
            .padding(.horizontal, 16)
        }
    }
}

private extension RoomPlanView {
    func loadBackground() async {
        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
            draft.background = UIImage(data: data)
        } else {
            print("Failed to load the image")
        }
    }

    func saveSpaceData() {
        guard let newSpace = draft.makeSpaceData(), modelContext.addSpace(space: newSpace) else {
            showSavedFailureAlert = true
            return
        }
        showSavedSuccessAlert = true
    }
}

#Preview {
    RoomPlanView()
        .modelContainer(for: SpaceData.self, inMemory: true)
}
