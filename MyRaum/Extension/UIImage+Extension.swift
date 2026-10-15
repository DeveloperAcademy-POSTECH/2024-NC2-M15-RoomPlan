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
