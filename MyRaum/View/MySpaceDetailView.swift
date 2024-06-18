//
//  MySpaceDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI
import UIKit

struct MySpaceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var space: SpaceData
    
    @State var showShare = false
    
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
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .frame(width: 320, height: 495)
                    .cornerRadius(19)
                    .foregroundColor(.white)
                    .overlay(
                        ZStack {
                            Image(uiImage: UIImage(data: space.background)!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 320, height: 495)
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
            
            Spacer()
            
            HStack {
                Button(action: {
                    
                }, label: {
                    Image("saveimage")
                        .resizable()
                        .frame(width:158, height:40)
                })
                .padding(.horizontal)
                
                Button(action: {
                    showShare = true
                }, label: {
                    Image("share")
                        .resizable()
                        .frame(width:105, height:40)
                })
                .sheet(isPresented: $showShare, content: {
                    ActivityViewController(activityItems: [space.model])
                })
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.presentationMode.wrappedValue.dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
        
    }
}
