//
//  RootView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI

//앱 상태에 따라 온보딩 / 로그인 / 홈 / 레거시 전용 모드를 분기하는 루트 뷰
struct RootView: View {
    @Environment(AppContainer.self) private var container
    
    @State private var router: AppRouter?
    
    var body: some View {
        Group {
            if let router {
                content(for: router)
            } else {
                launchingView
            }
        }
        .task {
            guard router == nil else { return }
            
            let newRouter = container.makeRouter()
            router = newRouter
            await newRouter.start()
        }
    }
}

private extension RootView {
    var launchingView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ProgressView()
                .tint(.white)
        }
    }
    
    @ViewBuilder
    func content(for router: AppRouter) -> some View {
        switch router.state {
        case .launching:
            launchingView
            
        case .onboarding:
            OnboardingView {
                router.completeOnboarding()
            }
            
        case .login:
            LoginView(
                authService: container.authService,
                showsLegacyEntry: router.hasLegacyCards,
                onAuthenticated: {
                    router.didAuthenticate()
                },
                onEnterLegacyOnly: {
                    router.enterLegacyOnlyMode()
                }
            )
            
        case .authenticated:
            HomeContainerView()
                .environment(router)
                //로그인 이후 서버의 공간을 내려받고 대기 중인 업로드를 처리한다
                .task {
                    await container.remoteRestoreService.restoreMissingSpaces()
                    container.syncQueue.startIfNeeded()
                }
            
        case .legacyOnly:
            LegacyOnlyView {
                router.requestSignIn()
            }
        }
    }
}
