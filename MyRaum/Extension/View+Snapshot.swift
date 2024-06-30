//
//  View+Snapshot.swift
//  MyRaum
//
//  Created by Yune Cho on 6/30/24.
//

import SwiftUI

//MySpaceCardView를 이미지로 변환하여 저장 및 공유하기 위한 View Extension
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
