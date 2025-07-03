//
//  RoomPlanView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import PhotosUI

//공간을 캡쳐하고 공간 카드를 만들기까지의 프로세스들을 구현한 뷰
struct RoomPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var roomPlanManager = RoomPlanManager()
    @State private var locationManager = LocationManager()
    @State private var modelCaptureManager = ModelCaptureManager()
    @State private var currentPage: Int = 0
    @State private var doneScanning: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var capturedView: UIImage?
    @State private var model: UIImage?
    @State private var background: UIImage?
    @State private var showCommentPopup: Bool = false
    @State private var comment: String = ""
    @State private var date: Date = Date.now
    @State private var dateString: String?
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var showSavedSuccessAlert: Bool = false
    @State private var showSavedFailureAlert: Bool = false
    
    var body: some View {
        TabView(selection: $currentPage, content:  {
            //방 캡쳐 화면 & 캡쳐 결과 확인 화면
            VStack{
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
                    Button(action: {
                        roomPlanManager.stopSession()
                        doneScanning = true
                    }, label: {
                        Image("scanfinish")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150)
                    })
                } else {
                    HStack {
                        Button(action: {
                            currentPage = 0
                            
                            doneScanning = false
                            roomPlanManager.startSession()
                        }, label: {
                            Image("scanagain")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        })
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image("addbg")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        }
                        .onChange(of: selectedItem) {
                            Task {
                                //배경 이미지를 선택할때 3D 모델은 화면 캡쳐 및 배경 제거를 통해 모델만 존재하는 이미지로 변환
                                //화면 캡쳐
                                capturedView = modelCaptureManager.captureScreen()
                                if let modelImage = capturedView {
                                    //배경 제거
                                    Task {
                                        model = await modelCaptureManager.createSticker(image: modelImage)
                                    }
                                }
                                
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    background = UIImage(data: data)
                                } else {
                                    print("Failed to load the image")
                                }
                                
                                currentPage = 1
                            }
                        }
                    }
                }
            }
            .tag(0)
            
            //방 모델 이미지 + 배경 이미지 화면
            ZStack {
                VStack{
                    Text("장소를 입력하세요.")
                        .bold()
                        .padding()
                    
                    NewCardView(model: $model, background: $background, date: $dateString, comment: $comment)
                    
                    Spacer()
                    
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image("editbg")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        }
                        .onChange(of: selectedItem) {
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    background = UIImage(data: data)
                                } else {
                                    print("Failed to load the image")
                                }
                            }
                        }
                        
                        Button(action: {
                            showCommentPopup = true
                        }, label: {
                            Image("addplace")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        })
                    }
                }
                
                if showCommentPopup {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                    
                    CommentPopupView(showCommentPopup: $showCommentPopup, currentPage: $currentPage, comment: $comment)
                }
            }
            .tag(1)
            
            //방 모델 이미지 + 배경 이미지 + 장소명 화면
            ZStack {
                VStack{
                    Text("결과물을 확인하세요.")
                        .bold()
                        .padding()
                    
                    NewCardView(model: $model, background: $background, date: $dateString, comment: $comment)
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            showCommentPopup = true
                        }, label: {
                            Image("editplace")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        })
                        
                        Button(action: {
                            //미리보기 버튼을 선택할때 현재의 날짜 정보 입력
                            date = Date.now
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy년 M월 d일"
                            dateString = formatter.string(from: date)
                            
                            //미리보기 버튼을 선택할때 현재의 위치 정보 입력
                            if let coordinate = locationManager.lastKnownLocation {
                                latitude = coordinate.latitude
                                longitude = coordinate.longitude
                            }
                            
                            currentPage = 3
                        }, label: {
                            Image("preview")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 56)
                        })
                    }
                }
                
                if showCommentPopup {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                    
                    CommentPopupView(showCommentPopup: $showCommentPopup, currentPage: $currentPage, comment: $comment)
                }
            }
            .tag(2)
            
            //최종 결과 확인 화면
            VStack{
                Text("결과물을 저장해보세요.")
                    .bold()
                    .padding()
                
                NewCardView(model: $model, background: $background, date: $dateString, comment: $comment)
                
                Spacer()
                
                Button(action: {
                    saveSpaceData()
                }, label: {
                    Image("save")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 56)
                })
                .alert("저장되었습니다.", isPresented: $showSavedSuccessAlert) {
                    Button {
                        doneScanning = false
                        currentPage = 0
                        dismiss()
                    } label: {
                        Text("확인")
                    }
                }
                .alert("저장하지 못했습니다.", isPresented: $showSavedFailureAlert) {
                    Button {
                        doneScanning = false
                        currentPage = 0
                        dismiss()
                    } label: {
                        Text("확인")
                    }
                }
            }
            .tag(3)
        })
    }
}

private extension RoomPlanView {
    func saveSpaceData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        let savedDate = formatter.string(from: date)
        
        if let model, let background {
            let newSpace = SpaceData(
                id: UUID(),
                date: savedDate,
                comment: comment,
                model: model.pngData()!,
                background: background.pngData()!,
                latitude: latitude,
                longitude: longitude
            )
            
            let result = modelContext.addSpace(space: newSpace)
            
            if result {
                showSavedSuccessAlert = true
            } else {
                showSavedFailureAlert = true
            }
        } else {
            showSavedFailureAlert = true
        }
    }
}

#Preview {
    RoomPlanView()
        .modelContainer(for: SpaceData.self)
}
