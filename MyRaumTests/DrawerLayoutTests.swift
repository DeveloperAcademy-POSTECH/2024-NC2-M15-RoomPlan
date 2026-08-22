//
//  DrawerLayoutTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import CoreGraphics
@testable import MyRaum

//사이드 드로어의 위치·전환 계산을 확인하는 테스트
struct DrawerLayoutTests {
    private let width: CGFloat = 400
    
    @Test("패널마다 완전히 열린 위치가 정해져 있다")
    func baseOffsets() {
        #expect(DrawerLayout.baseOffset(for: .archive, width: width) == 400)
        #expect(DrawerLayout.baseOffset(for: .home, width: width) == 0)
        #expect(DrawerLayout.baseOffset(for: .scan, width: width) == -400)
    }
    
    @Test("드래그 중 오프셋은 패널 너비를 넘지 않는다")
    func offsetIsClamped() {
        #expect(DrawerLayout.currentOffset(for: .archive, translation: 500, width: width) == 400)
        #expect(DrawerLayout.currentOffset(for: .scan, translation: -500, width: width) == -400)
        #expect(DrawerLayout.currentOffset(for: .home, translation: 120, width: width) == 120)
    }
    
    @Test("기준을 넘지 못하면 원래 패널에 그대로 머문다")
    func staysWhenBelowThreshold() {
        //기준은 너비의 25% = 100
        #expect(DrawerLayout.targetPanel(from: .home, translation: 80, width: width) == .home)
        #expect(DrawerLayout.targetPanel(from: .home, translation: -80, width: width) == .home)
    }
    
    @Test("홈에서 오른쪽으로 끌면 보관함이 열린다")
    func dragRightOpensArchive() {
        #expect(DrawerLayout.targetPanel(from: .home, translation: 150, width: width) == .archive)
    }
    
    @Test("홈에서 왼쪽으로 끌면 스캔이 열린다")
    func dragLeftOpensScan() {
        #expect(DrawerLayout.targetPanel(from: .home, translation: -150, width: width) == .scan)
    }
    
    @Test("열린 패널에서 반대로 끌면 홈으로 닫힌다")
    func dragBackClosesToHome() {
        #expect(DrawerLayout.targetPanel(from: .archive, translation: -150, width: width) == .home)
        #expect(DrawerLayout.targetPanel(from: .scan, translation: 150, width: width) == .home)
    }
    
    @Test("이미 끝까지 열린 방향으로는 더 이동하지 않는다")
    func doesNotOvershoot() {
        #expect(DrawerLayout.targetPanel(from: .archive, translation: 300, width: width) == .archive)
        #expect(DrawerLayout.targetPanel(from: .scan, translation: -300, width: width) == .scan)
    }
    
    @Test("너비가 0이면 패널을 바꾸지 않는다")
    func ignoresZeroWidth() {
        #expect(DrawerLayout.targetPanel(from: .home, translation: 999, width: 0) == .home)
    }
}
