//
//  MySpaceDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import Vision

struct MySpaceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var space: SpaceData
    
    @State private var card: UIImage = UIImage()
    @State private var showShare = false
    @State private var showSavedAlert = false
    @State private var cardFlipped = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "x.circle")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .bold()
                })
                .padding()
            }
            
            MySpaceCardView(space: space, cardFlipped: $cardFlipped)
                .onAppear(perform: {
                    let view = MySpaceCardView(space: space, cardFlipped: .constant(false))
                    card = view.snapshot()
                })
            
            Spacer()
            
            HStack {
                Button(action: {
                    UIImageWriteToSavedPhotosAlbum(card, nil, nil, nil)
                    showSavedAlert = true
                }, label: {
                    Image("saveimage")
                        .resizable()
                        .frame(width:158, height:40)
                })
                .padding(.horizontal)
                .alert("이미지가 저장되었습니다.", isPresented: $showSavedAlert) {
                    Button(action: {
                    }, label: {
                        Text("확인")
                    })
                }
                
                ShareLink(item: Image(uiImage: card), preview: SharePreview("공간 카드 공유", icon: "AppIcon")) {
                    Image("share")
                        .resizable()
                        .frame(width:105, height:40)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
