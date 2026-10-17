//
//  UIImage+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 6/30/24.
//

import UIKit

//이미지를 저장하거나 공유할 때 이미지의 크기를 적당하게 조절하기 위한 extension
extension UIImage {
    //targetSize는 픽셀 단위 (화면 배율을 곱하지 않음)
    func resize(to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

//3D 모델 이미지의 투명한 여백을 잘라내서 썸네일에서 모델만 보이도록 하는 extension
extension UIImage {
    private static let trimmedCache = NSCache<NSString, UIImage>()

    //같은 이미지를 목록에서 반복해서 그리므로 key로 잘라낸 결과를 캐시함
    func trimmingTransparentPixels(cacheKey: String) -> UIImage {
        if let cached = UIImage.trimmedCache.object(forKey: cacheKey as NSString) {
            return cached
        }
        let trimmed = trimmingTransparentPixels() ?? self
        UIImage.trimmedCache.setObject(trimmed, forKey: cacheKey as NSString)
        return trimmed
    }

    //큰 이미지는 작게 줄여서 투명하지 않은 영역을 찾은 뒤 원본에서 잘라냄
    private func trimmingTransparentPixels() -> UIImage? {
        guard let cgImage else { return nil }

        let maxSide = 256.0
        let ratio = min(1, maxSide / Double(max(cgImage.width, cgImage.height)))
        let width = max(1, Int(Double(cgImage.width) * ratio))
        let height = max(1, Int(Double(cgImage.height) * ratio))

        var alpha = [UInt8](repeating: 0, count: width * height)
        let found: Bool = alpha.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard found else { return nil }

        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where alpha[y * width + x] > 8 {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        //모두 투명하거나 여백이 없으면 원본을 그대로 사용
        guard maxX >= minX, maxY >= minY else { return nil }

        //줄인 이미지에서 찾은 영역을 원본 크기로 되돌리고, 잘리지 않도록 1픽셀씩 여유를 둠
        let factor = 1 / ratio
        let rect = CGRect(
            x: Double(max(minX - 1, 0)) * factor,
            y: Double(max(minY - 1, 0)) * factor,
            width: Double(min(maxX + 2, width) - max(minX - 1, 0)) * factor,
            height: Double(min(maxY + 2, height) - max(minY - 1, 0)) * factor
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: imageOrientation)
    }
}
