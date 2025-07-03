//
//  WhiteTextButton.swift
//  MyRaum
//
//  Created by Yune Cho on 7/4/25.
//

import SwiftUI

struct WhiteTextButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(Color.white)
                .frame(width: 142, height: 40)
                .overlay {
                    Text(text)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.black)
                }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        WhiteTextButton(text: "스캔하기", action: {})
    }
}
