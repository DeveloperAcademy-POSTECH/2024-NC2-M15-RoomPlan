//
//  HomeCenterView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//드로어 가운데에 놓이는 홈 화면
struct HomeCenterView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let onOpenArchive: () -> Void
    let onOpenScan: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()
                    
                    NavigationLink {
                        MyPageView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .foregroundStyle(Color.gray)
                            .padding(.top, 70)
                            .padding(.trailing, 16)
                            .symbolEffect(.breathe, options: .nonRepeating)
                    }
                }
                
                Spacer()
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                
                Text("나의 공간을 기록해보세요.")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                
                //공간 스캔 패널 열기
                TextButtonCapsule(text: "스캔하기", color: .white) {
                    onOpenScan()
                }
                .padding(.leading, 30)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    //보관함 패널 열기
                    Image("corner")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                        .overlay(alignment: .bottomTrailing, content: {
                            Text("보관함")
                                .font(.title3)
                                .foregroundStyle(Color.black)
                                .padding(24)
                        })
                        .onTapGesture {
                            onOpenArchive()
                        }
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
        .tint(colorScheme == .dark ? .white : .black)
    }
}
