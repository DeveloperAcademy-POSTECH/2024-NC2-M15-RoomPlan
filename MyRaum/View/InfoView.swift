//
//  InfoView.swift
//  MyRaum
//
//  Created by Yune Cho on 7/15/24.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Capsule()
                    .frame(width: 250, height: 170)
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                
                Capsule()
                    .frame(width: 240, height: 160)
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                
                Image("teemo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 160)
                    .offset(y: 10)
                    .clipShape(Capsule())
            }
            .padding()
            
            Text("김민정")
                .font(.title2)
                .bold()
                .padding(4)
            
            Text("UX/UI Designer")
            
            Spacer()
            
            ZStack {
                Capsule()
                    .frame(width: 250, height: 170)
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                
                Capsule()
                    .frame(width: 240, height: 160)
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                
                Image("raum")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 160)
                    .clipShape(Capsule())
            }
            .padding()
            
            Text("조윤")
                .font(.title2)
                .bold()
                .padding(4)
            
            Text("iOS Developer")
            
            Spacer()
            Spacer()
            
            Text(" Apple Developer Academy @ POSTECH")
                .foregroundStyle(Color.gray)
                .font(.caption)
        }
        .navigationTitle("My Raum을 만든 사람들")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InfoView()
}
