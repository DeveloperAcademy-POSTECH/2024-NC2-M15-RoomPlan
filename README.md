# 2024-NC2-M15-RoomPlan

## 🎥 Youtube Link (Click the image)
[![Video Label](https://github.com/DeveloperAcademy-POSTECH/2024-NC2-M15-RoomPlan/assets/52344592/6f631d09-955f-420c-bd7c-9b06ce0888b5)](https://youtu.be/Ne4yzAaqqkM?si=25OEI2bubSXvJbl4)

## 💡 About RoomPlan

<img width="600" alt="Untitled" src="https://github.com/DeveloperAcademy-POSTECH/2024-NC2-M15-RoomPlan/assets/52344592/f9e25cee-4259-4663-83ff-33f0d38ea918">
  
>RoomPlan은 카메라와 라이다센서를 활용해서 3D 평면도를 작성해주는 기술입니다.

>RoomPlan을 활용해서 다른 기술과 결합하여 벽의 색도 바꿔볼 수 있고 쓰이는 페인트의 양 까지 알 수 있습니다. 또한, 공간 설계, 가구 배치 등에도 활용할 수 있는 기술입니다.

>제약사항:  RoomPlan으로 공간을 스캔할 때는 5분을 초과하면 안되고 최대 스캔 범위는 9mX9m입니다. 그리고, 직육면체만 인식하고 곡선은 인식이 불가능합니다.

## 🎯 What we focus on?
- 애플에서 제공한 RoomPlan 예시 코드를 활용하여 공간을 캡쳐하는 기술 자체에 집중했습니다.
- 캡쳐된 모델을 USD, USDZ 등의 포맷으로 저장하는 것 외에는 모델을 활용할 방법이 마땅치 않아 캡쳐된 모델을 어떻게 사용해야할지 고민했습니다.
- 캡쳐된 모델을 이미지로 만들어서 다른 이미지, 텍스트 등의 요소들과 함께 배치하는 방식을 사용하기로 결정했습니다.

## 💼 Use Case
**RoomPlan과 Maps를 활용하여 생생하게 공간을 기록하고 공유할 수 있는 서비스를 만들어보자!**

## 🖼️ Prototype
- Prototype & User Flow
<img width="1932" alt="Untitled 2" src="https://github.com/DeveloperAcademy-POSTECH/2024-NC2-M15-RoomPlan/assets/52344592/18ca4200-5829-4d0a-a5f8-b17c2ff01d4e">

- 시연영상

https://github.com/DeveloperAcademy-POSTECH/2024-NC2-M15-RoomPlan/assets/52344592/330e2af1-cd0a-4aaf-a028-d8ba90d4cfa6

## 🛠️ About Code
- RoomPlan

```swift
import RoomPlan
```

```swift
//방 캡쳐를 담당하는 클래스
class RoomController: RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    //코드의 다른 부분에서 접근 가능하도록 싱글턴으로 인스턴스 생성
    static var instance = RoomController()
    
    var captureView: RoomCaptureView
    var sessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    var finalResult: CapturedRoom?
    
    init() {
        captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = self
    }
    
    //캡쳐가 완료되었는지 아닌지에 대해서 Bool 값을 리턴하는 함수
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    //캡쳐가 완료된 결과를 finalResult에 저장하는 함수
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        finalResult = processedResult
    }
    
    //캡쳐를 시작하는 함수
    func startSession() {
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    //캡쳐를 종료하는 함수
    func stopSession() {
        captureView.captureSession.stop()
    }
}
```

```swift
//UIKit으로 작성된 RoomPlan 뷰를 SwiftUI에서 보여지도록 UIViewRepresentable 프로토콜을 사용한 뷰
struct RoomCaptureViewRepresentable : UIViewRepresentable {
    //뷰를 생성하고 초기화하는 함수
    func makeUIView(context: Context) -> RoomCaptureView {
        RoomController.instance.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
```

- 모델 이미지화 및 배경 제거

```swift
//캡쳐된 모델이 보이는 뷰를 이미지로 캡쳐하기 위한 함수
//3D모델이 존재하는 부분만 캡쳐되도록 영역을 조정해서 이미지로 만듦
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
```

```swift
//이미지의 배경을 제거하는 함수
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
```

```swift
//이미지의 배경을 제거하기 위한 Mask를 만들어주는 함수
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
```

```swift
//이미지에 Mask를 적용하는 함수
func apply(mask: CIImage, to image: CIImage) -> CIImage {
    let filter = CIFilter.blendWithMask()
    filter.inputImage = image
    filter.maskImage = mask
    filter.backgroundImage = CIImage.empty()
    return filter.outputImage!
}
```

```swift
//이미지에 적용된 Mask에 따라 배경을 제거한 이미지를 리턴하는 함수
func render(ciImage: CIImage) -> UIImage {
    guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
        fatalError("Failed to render CGImage")
    }
    return UIImage(cgImage: cgImage)
}
```

- 정보 저장 및 관리(SwiftData)

```swift
@Model
final class SpaceData: Identifiable {
    var id: UUID
    var date: String
    var comment: String
    @Attribute(.externalStorage) var model: Data
    @Attribute(.externalStorage) var background: Data
    var latitude: Double
    var longitude: Double
    
    init(id: UUID, date: String, comment: String, model: Data, background: Data, latitude: Double, longitude: Double) {
        self.id = id
        self.date = date
        self.comment = comment
        self.model = model
        self.background = background
        self.latitude = latitude
        self.longitude = longitude
    }
}
```

```swift
//SwiftData에 공간 정보를 저장하는 함수
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
```

```swift
//SwiftData에서 데이터를 삭제하는 함수
func deleteSpace(space: SpaceData) {
    do {
        modelContext.delete(space)
        try modelContext.save()
    } catch {
        print("Failed to save data")
    }
}
```
