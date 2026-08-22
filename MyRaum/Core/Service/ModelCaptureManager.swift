//
//  ModelCaptureManager.swift
//  MyRaum
//
//  Created by Yune Cho on 6/28/25.
//

import UIKit
import Vision
import CoreImage.CIFilterBuiltins

final class ModelCaptureManager {
    //캡쳐된 모델이 보이는 뷰를 이미지로 캡쳐하기 위한 함수
    //3D모델이 존재하는 부분만 캡쳐되도록 영역을 조정해서 이미지로 만듦
    func captureScreen() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("Failed to get UIWindowScene")
            return nil
        }
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("Failed to get key window")
            return nil
        }
        guard let rootView = window.rootViewController?.view else {
            print("Failed to get root view")
            return nil
        }
        let topMargin: CGFloat = 100
        let bottomMargin: CGFloat = 300
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let rect = CGRect(x: 0, y: topMargin, width: screenWidth, height: screenHeight - topMargin - bottomMargin)
        return rootView.snapshot(of: rect)
    }
    
    //이미지의 배경을 제거하는 함수
    func createSticker(image: UIImage) async -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return nil
        }
        
        return await Task.detached(priority: .userInitiated) {
            guard let maskImage = self.subjectMaskImage(from: inputImage) else {
                print("Failed to create mask image")
                return nil
            }
            guard let outputImage = self.apply(mask: maskImage, to: inputImage) else {
                print("Failed to apply mask image")
                return nil
            }
            return self.render(ciImage: outputImage)
        }.value
    }
    
    //이미지의 배경을 제거하기 위한 Mask를 만들어주는 함수
    private func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
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
            print(error.localizedDescription)
            return nil
        }
    }
    
    //이미지에 Mask를 적용하는 함수
    private func apply(mask: CIImage, to image: CIImage) -> CIImage? {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage
    }
    
    //이미지에 적용된 Mask에 따라 배경을 제거한 이미지를 리턴하는 함수
    private func render(ciImage: CIImage) -> UIImage? {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
