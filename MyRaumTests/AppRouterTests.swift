//
//  AppRouterTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//앱 진입 분기 로직을 확인하는 테스트 (PRD 6-A)
@MainActor
struct AppRouterTests {
    private func makeRouter(
        auth: FakeAuthService? = nil,
        onboardingDone: Bool = false,
        legacyCount: Int = 0
    ) -> AppRouter {
        AppRouter(
            authService: auth ?? FakeAuthService(),
            onboardingStore: InMemoryOnboardingStore(hasCompletedOnboarding: onboardingDone),
            legacyCardCount: { legacyCount }
        )
    }
    
    @Test("온보딩을 보지 않은 사용자는 온보딩으로 간다")
    func newUserSeesOnboarding() async {
        let router = makeRouter(onboardingDone: false)
        
        await router.start()
        
        #expect(router.state == .onboarding)
    }
    
    @Test("온보딩을 마쳤고 세션이 있으면 바로 홈으로 간다")
    func returningUserWithSessionGoesHome() async {
        let router = makeRouter(auth: FakeAuthService(currentUserID: "user"), onboardingDone: true)
        
        await router.start()
        
        //세션이 유효한 동안에는 재실행 시 로그인을 다시 요구하지 않는다 (NFR-08)
        #expect(router.state == .authenticated)
    }
    
    @Test("온보딩을 마쳤지만 세션이 없으면 로그인 화면으로 간다")
    func returningUserWithoutSessionSeesLogin() async {
        let router = makeRouter(onboardingDone: true)
        
        await router.start()
        
        //온보딩은 다시 보여주지 않는다
        #expect(router.state == .login)
    }
    
    @Test("온보딩을 마치면 로그인 화면으로 이동하고 기록이 남는다")
    func completingOnboardingMovesToLogin() {
        let store = InMemoryOnboardingStore(hasCompletedOnboarding: false)
        let router = AppRouter(
            authService: FakeAuthService(),
            onboardingStore: store,
            legacyCardCount: { 0 }
        )
        
        router.completeOnboarding()
        
        #expect(router.state == .login)
        #expect(store.hasCompletedOnboarding == true)
    }
    
    @Test("레거시 카드가 있어야 기존 데이터 보기가 노출된다")
    func legacyEntryRequiresLegacyCards() {
        #expect(makeRouter(legacyCount: 0).hasLegacyCards == false)
        #expect(makeRouter(legacyCount: 3).hasLegacyCards == true)
    }
    
    @Test("레거시 데이터가 0건이면 제한 모드로 들어갈 수 없다")
    func cannotEnterLegacyOnlyWithoutData() async {
        let router = makeRouter(onboardingDone: true, legacyCount: 0)
        await router.start()
        
        router.enterLegacyOnlyMode()
        
        #expect(router.state == .login)
    }
    
    @Test("레거시 데이터가 있으면 제한 모드로 들어간다")
    func entersLegacyOnlyWithData() async {
        let router = makeRouter(onboardingDone: true, legacyCount: 2)
        await router.start()
        
        router.enterLegacyOnlyMode()
        
        #expect(router.state == .legacyOnly)
    }
    
    @Test("제한 모드에서 로그인하면 전체 기능으로 전환된다")
    func legacyOnlyCanSignIn() async {
        let router = makeRouter(onboardingDone: true, legacyCount: 2)
        await router.start()
        router.enterLegacyOnlyMode()
        
        router.requestSignIn()
        #expect(router.state == .login)
        
        router.didAuthenticate()
        #expect(router.state == .authenticated)
    }
    
    @Test("로그아웃하면 로그인 화면으로 돌아간다")
    func signOutReturnsToLogin() async {
        let auth = FakeAuthService(currentUserID: "user")
        let router = makeRouter(auth: auth, onboardingDone: true)
        await router.start()
        
        await router.signOut()
        
        #expect(router.state == .login)
        #expect(auth.signOutCallCount == 1)
    }
    
    @Test("계정을 삭제하면 로그인 화면으로 돌아간다")
    func deleteAccountReturnsToLogin() async throws {
        let auth = FakeAuthService(currentUserID: "user")
        let router = makeRouter(auth: auth, onboardingDone: true)
        await router.start()
        
        try await router.deleteAccount()
        
        #expect(router.state == .login)
        #expect(auth.deleteAccountCallCount == 1)
    }
}
