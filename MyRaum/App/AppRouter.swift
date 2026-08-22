//
//  AppRouter.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//앱 진입 상태
enum AppState: Equatable {
    //세션 복원 중
    case launching
    case onboarding
    case login
    //로그인 완료 — 전체 기능
    case authenticated
    //로그인 없이 레거시 카드만 조회하는 제한 모드
    case legacyOnly
}

//온보딩 완료 여부를 보관하는 역할
protocol OnboardingStateStoring: AnyObject {
    var hasCompletedOnboarding: Bool { get set }
}

//UserDefaults에 온보딩 완료 여부를 저장하는 구현체
final class OnboardingStateStore: OnboardingStateStoring {
    private let key = "hasCompletedOnboarding"
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

//앱 진입 분기를 담당하는 라우터 (PRD 6-A)
@Observable
@MainActor
final class AppRouter {
    private(set) var state: AppState = .launching
    
    private let authService: any AuthProviding
    private let onboardingStore: any OnboardingStateStoring
    private let legacyCardCount: () -> Int
    
    init(
        authService: any AuthProviding,
        onboardingStore: any OnboardingStateStoring,
        legacyCardCount: @escaping () -> Int
    ) {
        self.authService = authService
        self.onboardingStore = onboardingStore
        self.legacyCardCount = legacyCardCount
    }
    
    //레거시 카드가 1건 이상 있을 때만 "기존 데이터 보기"를 노출한다
    var hasLegacyCards: Bool {
        legacyCardCount() > 0
    }
    
    //앱 실행 시 분기 로직
    func start() async {
        await authService.restoreSession()
        
        guard onboardingStore.hasCompletedOnboarding else {
            state = .onboarding
            return
        }
        
        //세션이 유효하면 재실행마다 로그인을 요구하지 않는다 (NFR-08)
        state = authService.isAuthenticated ? .authenticated : .login
    }
    
    //온보딩을 마치면 로그인 화면으로
    func completeOnboarding() {
        onboardingStore.hasCompletedOnboarding = true
        state = .login
    }
    
    //로그인에 성공하면 전체 기능으로
    func didAuthenticate() {
        state = .authenticated
    }
    
    //레거시 데이터가 없으면 제한 모드로 들어갈 수 없다
    func enterLegacyOnlyMode() {
        guard hasLegacyCards else { return }
        state = .legacyOnly
    }
    
    //제한 모드에서 언제든 로그인 화면으로 돌아갈 수 있다
    func requestSignIn() {
        state = .login
    }
    
    //로그아웃하면 로그인 화면으로 돌아간다. 온보딩은 다시 보여주지 않는다
    func signOut() async {
        try? await authService.signOut()
        state = .login
    }
    
    func deleteAccount() async throws {
        try await authService.deleteAccount()
        state = .login
    }
}
