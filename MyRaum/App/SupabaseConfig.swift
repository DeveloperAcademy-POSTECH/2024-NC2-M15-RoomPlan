//
//  SupabaseConfig.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//Supabase 접속 정보
//키를 저장소에 커밋하지 않기 위해 번들에 포함된 Supabase-Info.plist에서 읽는다
//파일이 없으면 원격 기능만 꺼지고 앱은 그대로 동작한다 (docs/supabase-setup.md 참고)
struct SupabaseConfig {
    let url: URL
    let anonKey: String
    
    static let resourceName = "Supabase-Info"
    
    static func loadFromBundle(_ bundle: Bundle = .main) -> SupabaseConfig? {
        guard let path = bundle.path(forResource: resourceName, ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Supabase-Info.plist not found — remote features are disabled")
            return nil
        }
        
        return make(from: values)
    }
    
    //plist 딕셔너리에서 설정을 만드는 함수
    static func make(from values: [String: Any]) -> SupabaseConfig? {
        guard let urlString = values["SupabaseURL"] as? String,
              urlString.isEmpty == false,
              let url = URL(string: urlString),
              url.scheme != nil,
              let anonKey = values["SupabaseAnonKey"] as? String,
              anonKey.isEmpty == false else {
            print("Supabase-Info.plist is missing SupabaseURL or SupabaseAnonKey")
            return nil
        }
        
        return SupabaseConfig(url: url, anonKey: anonKey)
    }
}
