//
//  DrawerLayout.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import CoreGraphics

//사이드 드로어의 위치 계산을 담당하는 값 타입
//뷰에서 떼어 놓아 계산만 따로 검증할 수 있게 한다
enum DrawerLayout {
    //드래그를 끝냈을 때 패널이 바뀌는 기준 (패널 너비 대비)
    static let switchThresholdRatio: CGFloat = 0.25
    
    //패널이 완전히 열렸을 때의 오프셋
    static func baseOffset(for panel: HomePanel, width: CGFloat) -> CGFloat {
        switch panel {
        case .archive: return width
        case .home: return 0
        case .scan: return -width
        }
    }
    
    //드래그 중인 현재 오프셋. 양 끝을 넘어가지 않도록 잘라낸다
    static func currentOffset(for panel: HomePanel, translation: CGFloat, width: CGFloat) -> CGFloat {
        let offset = baseOffset(for: panel, width: width) + translation
        return min(max(offset, -width), width)
    }
    
    //드래그를 끝냈을 때 붙을 패널을 결정하는 함수
    static func targetPanel(from panel: HomePanel, translation: CGFloat, width: CGFloat) -> HomePanel {
        guard width > 0 else { return panel }
        
        let threshold = width * switchThresholdRatio
        
        //오른쪽으로 끌면 좌측 패널(보관함) 방향으로 한 칸 이동
        if translation > threshold {
            return step(from: panel, towardArchive: true)
        }
        //왼쪽으로 끌면 우측 패널(스캔) 방향으로 한 칸 이동
        if translation < -threshold {
            return step(from: panel, towardArchive: false)
        }
        
        return panel
    }
    
    private static func step(from panel: HomePanel, towardArchive: Bool) -> HomePanel {
        switch (panel, towardArchive) {
        case (.home, true): return .archive
        case (.home, false): return .scan
        case (.scan, true): return .home
        case (.archive, false): return .home
        //이미 끝까지 열린 방향으로는 더 이동하지 않는다
        case (.archive, true): return .archive
        case (.scan, false): return .scan
        }
    }
}
