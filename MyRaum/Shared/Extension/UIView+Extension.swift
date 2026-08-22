//
//  UIView+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 6/30/24.
//

import UIKit

//캡쳐된 모델이 보이는 뷰를 이미지로 변환하기 위한 View Extension
extension UIView {
    func snapshot(of rect: CGRect) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { ctx in
            self.drawHierarchy(in: CGRect(x: -rect.origin.x, y: -rect.origin.y, width: self.bounds.width, height: self.bounds.height), afterScreenUpdates: true)
        }
    }
}
