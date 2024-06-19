//
//  MySpaceCardView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import SwiftUI

struct MySpaceCardView: View {
    var space: SpaceData
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 315, height: 560)
                .cornerRadius(19)
                .foregroundColor(.white)
                .overlay(
                    ZStack {
                        Image(uiImage: UIImage(data: space.background)!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 315, height: 560)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                        
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image("locationpin")
                                    .resizable()
                                    .frame(width:17, height:21)
                                
                                Text(space.comment)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            
                            Spacer()
                            
                            Image(uiImage: UIImage(data: space.model)!)
                                .resizable()
                                .scaledToFit()
                            
                            Spacer()
                            
                            HStack {
                                Image("logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 30)
                                    .padding()
                                    .opacity(0.4)
                                
                                Spacer()
                                
                                Text(space.date)
                                    .font(.system(size: 23, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .padding()
                            }
                            
                            Spacer()
                        }
                        
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.gray, lineWidth: 2)
                    }
                )
        }
    }
}

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
