//
//  LoginView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import AuthenticationServices

//Sign in with Apple 로그인 화면 (6A.3)
struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let authService: any AuthProviding
    //레거시 카드가 1건 이상 있을 때만 "기존 데이터 보기"를 노출한다 (6A.4)
    let showsLegacyEntry: Bool
    let onAuthenticated: () -> Void
    let onEnterLegacyOnly: () -> Void
    
    @State private var currentNonce: String = ""
    @State private var errorMessage: String?
    @State private var isSigningIn: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 240)
            
            Text("나의 공간을 기록해보세요.")
                .font(.title3)
                .bold()
                .foregroundStyle(Color.white)
                .padding(.top, 16)
            
            Spacer()
            
            SignInWithAppleButton(.signIn) { request in
                let nonce = AppleSignInNonce.makeRandom()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                //Apple에는 해시를 넘기고, 서버 검증에는 원본을 넘긴다
                request.nonce = AppleSignInNonce.sha256(nonce)
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .padding(.horizontal, 30)
            .disabled(isSigningIn)
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
            }
            
            if showsLegacyEntry {
                Button {
                    onEnterLegacyOnly()
                } label: {
                    Text("기존 데이터 보기")
                        .font(.footnote)
                        .underline()
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .padding(.top, 24)
            }
            
            Spacer()
                .frame(height: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private extension LoginView {
    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = String(localized: "Apple 로그인 정보를 받지 못했습니다.")
                return
            }
            
            signIn(idToken: idToken)
            
        case .failure(let error):
            //사용자가 직접 취소한 경우는 오류로 보여주지 않는다
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
    
    func signIn(idToken: String) {
        isSigningIn = true
        errorMessage = nil
        
        Task {
            defer { isSigningIn = false }
            
            do {
                try await authService.signInWithApple(idToken: idToken, nonce: currentNonce)
                onAuthenticated()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
