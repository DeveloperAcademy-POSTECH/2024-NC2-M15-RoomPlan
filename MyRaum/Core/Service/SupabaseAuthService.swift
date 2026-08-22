//
//  SupabaseAuthService.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import Supabase

//Supabase Auth의 Apple provider를 사용하는 로그인 구현체 (6B.2)
@MainActor
@Observable
final class SupabaseAuthService: AuthProviding {
    private(set) var currentUserID: String?
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    //저장된 세션을 복원한다. 네트워크가 없어도 로컬 세션으로 진입할 수 있어야 한다 (NFR-08)
    func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUserID = session.user.id.uuidString
        } catch {
            print("No restorable session: \(error)")
            currentUserID = nil
        }
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        currentUserID = session.user.id.uuidString
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        currentUserID = nil
    }
    
    //계정 삭제는 서버의 delete_current_user() 함수를 호출한다
    //auth.users는 클라이언트 권한으로 지울 수 없으므로 security definer 함수를 둔다
    func deleteAccount() async throws {
        try await client.rpc("delete_current_user").execute()
        try await client.auth.signOut()
        currentUserID = nil
    }
}

//Supabase 설정이 없을 때 사용하는 대체 구현
//로그인은 실패하지만 앱이 크래시하지 않고 레거시 조회 경로는 계속 쓸 수 있다
@MainActor
@Observable
final class UnconfiguredAuthService: AuthProviding {
    private(set) var currentUserID: String?
    
    func restoreSession() async {}
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        throw AuthError.notConfigured
    }
    
    func signOut() async throws {}
    
    func deleteAccount() async throws {
        throw AuthError.notConfigured
    }
}
