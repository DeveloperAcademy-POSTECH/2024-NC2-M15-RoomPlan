//
//  UnsupportedDeviceView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        VStack {
            Text("지원하지 않는 기기입니다.")
                .font(.title)
                .bold()
                .foregroundColor(.red)
                .padding()
            
            Text("이 기기는 라이다(LiDAR)를 지원하지 않습니다.")
                .padding()
        }
    }
}

#Preview {
    UnsupportedDeviceView()
}
