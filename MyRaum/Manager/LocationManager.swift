//
//  LocationManager.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import Foundation
import SwiftUI
import CoreLocation

//공간을 스캔한 위치를 가져오는 클래스
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private(set) var lastKnownLocation: CLLocationCoordinate2D?
    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    //위치 권한이 없으면 권한을 요청하고, 권한이 있으면 위치 업데이트를 시작
    func checkLocationAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            lastKnownLocation = manager.location?.coordinate
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.last?.coordinate
    }
}
