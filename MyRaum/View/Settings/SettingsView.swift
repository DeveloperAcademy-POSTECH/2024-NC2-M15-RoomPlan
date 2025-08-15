//
//  SettingsView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/15/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            navigationCell(title: "My Raum을 만든 사람들") {
                InfoView()
            }
            
            Spacer()
            
            Text("[Version \(AppEnvironment.version)]")
                .foregroundStyle(Color.gray)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SettingsView {
    func navigationCell<T: View>(title: String, @ViewBuilder destination: @escaping () -> T) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                }
                .padding(.vertical, 16)
                
                Divider()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
