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
import CoreLocation

struct RoomPlanView: View {
    var roomController = RoomController.instance
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @StateObject private var locationManager = LocationManager()
    
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
    @State private var showSavedAlert: Bool = false
    
    var body: some View {
        TabView(selection: $currentPage, content:  {
            //방 캡처 화면 & 캡처 결과 확인 화면
            VStack{
                if doneScanning == true {
                    Text("3D 모델의 각도를 조절한 후\n배경을 추가하세요.")
                        .bold()
                        .multilineTextAlignment(.center)
                }
                
                RoomCaptureViewRepresentable()
                    .onAppear(perform: {
                        roomController.startSession()
                        locationManager.checkLocationAuthorization()
                    })
                    .ignoresSafeArea(.all)
                
                if doneScanning == false {
                    Button(action: {
                        roomController.stopSession()
                        self.doneScanning = true
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
                            
                            self.doneScanning = false
                            roomController.startSession()
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
            
            //방 모델 이미지 + 배경 이미지 + 코멘트 화면
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
                            date = Date.now
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy년 M월 d일"
                            dateString = formatter.string(from: date)
                            
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
                    addSpace()
                    showSavedAlert = true
                }, label: {
                    Image("save")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 56)
                })
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
            .tag(3)
        })
    }
    
    func captureScreen() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                let rootView = window.rootViewController?.view
                let topMargin: CGFloat = 100
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
                        comment: comment,
                        model: model.pngData()!,
                        background: background.pngData()!,
                        latitude: latitude,
                        longitude: longitude
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
