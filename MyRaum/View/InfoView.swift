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
            
            infoCell(name: "김민정", role: "UX/UI Designer", image: "teemo")
            
            Spacer()
            
            infoCell(name: "조윤", role: "iOS Developer", image: "raum")
            
            Spacer()
            
            Text(" Apple Developer Academy @ POSTECH")
                .foregroundStyle(Color.gray)
                .font(.caption)
        }
        .navigationTitle("My Raum을 만든 사람들")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension InfoView {
    func infoCell(name: String, role: String, image: String) -> some View {
        VStack {
            ZStack {
                Capsule()
                    .frame(width: 250, height: 170)
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                
                Capsule()
                    .frame(width: 240, height: 160)
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 160)
                    .offset(y: 10)
                    .clipShape(Capsule())
            }
            .padding()
            
            Text(name)
                .font(.title2)
                .bold()
                .padding(4)
            
            Text(role)
        }
    }
}

#Preview {
    NavigationStack {
        InfoView()
    }
}
