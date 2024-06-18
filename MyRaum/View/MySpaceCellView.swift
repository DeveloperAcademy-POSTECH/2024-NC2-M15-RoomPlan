//
//  MySpaceCellView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

struct MySpaceCellView: View {
    var space: SpaceData
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 169, height: 262)
                .cornerRadius(19)
                .foregroundStyle(Color.white)
                .overlay(
                    ZStack {
                        Image(uiImage: UIImage(data: space.background)!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 169, height: 262)
                            .overlay(Color.black.opacity(0.4))
                            .cornerRadius(19)
                            .clipped()
                        
                        HStack {
                            Image("locationpin")
                                .resizable()
                                .frame(width:17, height:21)
                            
                            Text(space.comment)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color.gray, lineWidth: 2)
                    }
                )
            
            Path { path in
                path.move(to: CGPoint(x : 100, y : 200))
                path.addLine (to : CGPoint(x: 100, y : 200))
                path.addLine (to : CGPoint(x: 55, y : 200))
                path.addLine (to : CGPoint(x: 100, y : 150))
            }
            .fill(Color.gray)
            .offset(x: 82, y: 63)
        }
    }
}
