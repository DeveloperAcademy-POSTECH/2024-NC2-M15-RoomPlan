//
//  ScanStepIndicator.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//캡쳐 → 편집 진행 상황을 보여주는 상단 인디케이터
struct ScanStepIndicator: View {
    let step: ScanStep
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(ScanStep.allCases, id: \.rawValue) { each in
                Capsule()
                    .frame(height: 4)
                    .foregroundStyle(each.order <= step.order ? Color.white : Color.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
    }
}
