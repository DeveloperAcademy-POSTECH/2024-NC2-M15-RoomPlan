//
//  AppEnvironment.swift
//  MyRaum
//
//  Created by Yune Cho on 6/28/25.
//

import Foundation

struct AppEnvironment {
    static let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}
