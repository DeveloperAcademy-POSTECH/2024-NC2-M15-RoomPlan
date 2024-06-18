//
//  RoomPlanView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import SwiftData
import RoomPlan
import PhotosUI
import UIKit
import Vision
import CoreImage.CIFilterBuiltins

struct RoomPlanView: View {
    var roomController = RoomController.instance
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var currentPage: Int = 0
    @State private var doneScanning: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var capturedView: UIImage?
    @State private var model: UIImage?
    @State private var background: UIImage?
    @State private var showCommentPopup: Bool = false
    @State private var comment: String = ""
    @State private var date: Date = Date.now
    @State private var showSavedAlert: Bool = false
    
    var body: some View {
        TabView(selection: $currentPage, content:  {
            //방 캡처 화면 & 캡처 결과 확인 화면
            VStack{
                RoomCaptureViewRepresentable()
                    .onAppear(perform: {
                        roomController.startSession()
                    })
                    .ignoresSafeArea(.all)
                
                if doneScanning == false {
                    Button(action: {
                        roomController.stopSession()
                        self.doneScanning = true
                    }, label: {
                        Text("스캔 끝내기")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                } else {
                    HStack {
                        Button(action: {
                            currentPage = 0
                            self.doneScanning = false
                            roomController.startSession()
                        }, label: {
                            Text("다시 스캔하기")
                                .padding(10)
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("배경 추가하기")
                                .padding(10)
                        }
                        .onChange(of: selectedItem) {
                            Task {
                                captureScreen()
                                if let modelImage = capturedView {
                                    createSticker(image: modelImage)
                                }
                                
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    background = UIImage(data: data)
                                } else {
                                    print("Failed to load the image")
                                }
                                
                                currentPage = 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
                    }
                }
            }
            .tag(0)
            
            //방 모델 이미지 + 배경 이미지 화면
            ZStack {
                VStack{
                    ZStack {
                        if let background {
                            Image(uiImage: background)
                                .resizable()
                                .scaledToFit()
                        }
                        
                        if let model {
                            Image(uiImage: model)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Text("모델 없음")
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("배경 수정하기")
                                .padding(10)
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
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
                        
                        Button(action: {
                            showCommentPopup = true
                        }, label: {
                            Text("코멘트 추가하기")
                                .padding(10)
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
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
            
            //방 모델 이미지 + 배경 이미지 + 코멘트 화면
            ZStack {
                VStack{
                    ZStack {
                        if let background {
                            Image(uiImage: background)
                                .resizable()
                                .scaledToFit()
                        }
                        
                        if let model {
                            Image(uiImage: model)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Text("모델 없음")
                        }
                        
                        Text(comment)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            showCommentPopup = true
                        }, label: {
                            Text("코멘트 수정하기")
                                .padding(10)
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
                        
                        Button(action: {
                            
                            
                            currentPage = 3
                        }, label: {
                            Text("음악 추가하기")
                                .padding(10)
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(30)
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
                ZStack {
                    if let background {
                        Image(uiImage: background)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    if let model {
                        Image(uiImage: model)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("모델 없음")
                    }
                    
                    Text(comment)
                }
                
                Spacer()
                
                HStack {
                    Button(action: {
                        
                    }, label: {
                        Text("음악 수정하기")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                    
                    Button(action: {
                        addSpace()
                        showSavedAlert = true
                    }, label: {
                        Text("저장")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                    .alert("저장되었습니다.", isPresented: $showSavedAlert) {
                        Button(action: {
                            self.doneScanning = false
                            currentPage = 0
                            dismiss()
                        }, label: {
                            Text("확인")
                        })
                    }
                }
            }
            .tag(3)
        })
        .padding(.bottom, 10)
    }
    
    func captureScreen() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                let rootView = window.rootViewController?.view
                let topMargin: CGFloat = 50
                let bottomMargin: CGFloat = 300
                let screenHeight = UIScreen.main.bounds.height
                let screenWidth = UIScreen.main.bounds.width
                let rect = CGRect(x: 0, y: topMargin, width: screenWidth, height: screenHeight - topMargin - bottomMargin)
                capturedView = rootView?.snapshot(of: rect)
            }
        }
    }
    
    func createSticker(image: UIImage) {
        let processingQueue = DispatchQueue(label: "ProcessingQueue")
        
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return
        }
        processingQueue.async {
            guard let maskImage = subjectMaskImage(from: inputImage) else {
                print("Failed to create mask image")
                DispatchQueue.main.async {
                }
                return
            }
            let outputImage = apply(mask: maskImage, to: inputImage)
            let image = render(ciImage: outputImage)
            DispatchQueue.main.async {
                self.model = image
            }
        }
    }
    
    func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                print("No observations found")
                return nil
            }
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print(error)
            return nil
        }
    }
    
    func apply(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }
    
    func render(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage)
    }
    
    func addSpace() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        let savedDate = formatter.string(from: date)
        
        do {
            if let model {
                if let background {
                    let newSpace = SpaceData(
                        id: UUID(),
                        date: savedDate,
                        model: model.jpegData(compressionQuality: 1.0)!,
                        background: background.jpegData(compressionQuality: 1.0)!,
                        comment: comment,
                        music: ""
                    )
                    
                    modelContext.insert(newSpace)
                    try modelContext.save()
                }
            }
        } catch {
            print("Failed to save data")
        }
    }
}

extension UIView {
    func snapshot(of rect: CGRect) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { ctx in
            self.drawHierarchy(in: CGRect(x: -rect.origin.x, y: -rect.origin.y, width: self.bounds.width, height: self.bounds.height), afterScreenUpdates: true)
        }
    }
}

#Preview {
    RoomPlanView()
        .modelContainer(for: SpaceData.self)
}
