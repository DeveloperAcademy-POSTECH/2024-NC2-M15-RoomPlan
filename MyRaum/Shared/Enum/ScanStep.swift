//
//  ScanStep.swift
//  MyRaum
//
//  Created by Yune Cho on 12/3/25.
//

import Foundation

//스캔 플로우의 단계
//2.0에서 4단계 화면 전환을 캡쳐 + 단일 편집 캔버스 두 단계로 합쳤다
enum ScanStep: Int, CaseIterable {
    //공간 캡쳐
    case capture
    //카드 편집 캔버스
    case edit
    
    //상단 진행 인디케이터에 표시할 순번
    var order: Int { rawValue }
    
    static var stepCount: Int { allCases.count }
}
