//
//  HomeContainerView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//좌측 보관함 / 중앙 홈 / 우측 공간 스캔을 좌우 슬라이드로 오가는 홈 컨테이너
struct HomeContainerView: View {
    @Environment(AppContainer.self) private var container
    
    @State private var panel: HomePanel = .home
    @State private var dragTranslation: CGFloat = 0
    //스캔이 진행 중일 때는 드로어 제스처가 스캔 화면 제스처와 충돌하므로 비활성화한다
    @State private var isScanActive: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let offset = DrawerLayout.currentOffset(for: panel, translation: dragTranslation, width: width)
            
            ZStack {
                HomeCenterView(
                    onOpenArchive: { open(.archive) },
                    onOpenScan: { open(.scan) }
                )
                .offset(x: offset)
                //패널이 열려 있으면 중앙을 탭해서 닫는다
                .overlay {
                    if panel != .home {
                        Color.black.opacity(0.001)
                            .onTapGesture { open(.home) }
                    }
                }
                
                //좌측 패널 — 열리는 방향으로 움직일 때만 만든다
                if offset > 0 {
                    archivePanel
                        .frame(width: width)
                        .offset(x: -width + offset)
                        .transition(.identity)
                }
                
                //우측 패널
                if offset < 0 {
                    scanPanel
                        .frame(width: width)
                        .offset(x: width + offset)
                        .transition(.identity)
                }
            }
            .frame(width: width, height: proxy.size.height)
            .background(Color.black)
            .contentShape(Rectangle())
            .gesture(isScanActive ? nil : drawerGesture(width: width))
        }
        .ignoresSafeArea()
    }
}

private extension HomeContainerView {
    var archivePanel: some View {
        NavigationStack {
            MySpacesView(onClose: { open(.home) })
        }
    }
    
    var scanPanel: some View {
        NavigationStack {
            ScanFlowView(
                container: container,
                onScanActiveChange: { isScanActive = $0 },
                onFinish: {
                    isScanActive = false
                    open(.home)
                }
            )
        }
    }
    
    //좌우 슬라이드로 패널을 여닫는 제스처
    func drawerGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                //세로 스크롤과 헷갈리지 않도록 가로 이동이 더 클 때만 반응한다
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                let target = DrawerLayout.targetPanel(from: panel, translation: value.translation.width, width: width)
                
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
                    panel = target
                    dragTranslation = 0
                }
            }
    }
    
    func open(_ target: HomePanel) {
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
            panel = target
            dragTranslation = 0
        }
    }
}
