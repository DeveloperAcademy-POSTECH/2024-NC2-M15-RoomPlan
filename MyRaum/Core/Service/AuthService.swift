//
//  AuthService.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//로그인 상태를 관리하는 역할
@MainActor
protocol AuthProviding: AnyObject {
    //로그인한 사용자의 식별자. 로그인하지 않았으면 nil
    var currentUserID: String? { get }
    //Supabase가 저장해 둔 세션을 복원한다. 오프라인에서도 동작해야 한다
    func restoreSession() async
    //Sign in with Apple로 받은 토큰으로 로그인한다
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async throws
    //계정과 서버에 저장된 공간을 모두 삭제한다
    func deleteAccount() async throws
}

extension AuthProviding {
    var isAuthenticated: Bool { currentUserID != nil }
}

enum AuthError: LocalizedError {
    //Supabase 설정이 없어 로그인할 수 없는 상태
    case notConfigured
    case missingIdentityToken
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "서버 설정이 없어 로그인할 수 없습니다."
        case .missingIdentityToken:
            return "Apple 로그인 정보를 받지 못했습니다."
        }
    }
}
