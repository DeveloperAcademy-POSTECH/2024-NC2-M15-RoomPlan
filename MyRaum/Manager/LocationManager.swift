//
//  LocationManager.swift
//  MyRaum
//
//  Created by Yune Cho on 6/19/24.
//

import Foundation
import SwiftUI
import CoreLocation

//MapKit에 표시하기 위한 위치를 가져오는 클래스
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var lastKnownLocation: CLLocationCoordinate2D?
    private var manager = CLLocationManager()
    
    func checkLocationAuthorization() {
        manager.delegate = self
        manager.startUpdatingLocation()
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("Location restricted")
        case .denied:
            print("Location denied")
        case .authorizedAlways:
            print("Location authorizedAlways")
        case .authorizedWhenInUse:
            print("Location authorized when in use")
            lastKnownLocation = manager.location?.coordinate
        @unknown default:
            print("Location service disabled")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.first?.coordinate
    }
}
