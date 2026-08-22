//
//  AppleSignInNonce.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import CryptoKit

//Sign in with Apple 재생 공격을 막기 위한 nonce 처리
enum AppleSignInNonce {
    //요청에 담을 원본 nonce를 만드는 함수
    static func makeRandom(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        
        for _ in 0..<length {
            //보안상 예측 불가능한 값이어야 하므로 시스템 난수를 사용한다
            var byte: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
            
            if status == errSecSuccess {
                result.append(charset[Int(byte) % charset.count])
            } else {
                result.append(charset.randomElement() ?? "0")
            }
        }
        
        return result
    }
    
    //Apple에 전달할 때는 SHA256 해시를 넘긴다
    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
