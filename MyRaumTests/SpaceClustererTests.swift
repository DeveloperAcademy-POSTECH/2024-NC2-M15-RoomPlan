//
//  SpaceClustererTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
import CoreLocation
import MapKit
@testable import MyRaum

//지도 마커 묶기 동작을 확인하는 테스트 (Phase 7)
struct SpaceClustererTests {
    private func annotation(lat: Double, lng: Double, structureID: UUID? = nil) -> SpaceAnnotation {
        SpaceAnnotation(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            structureID: structureID
        )
    }
    
    private let wideSpan = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    private let tightSpan = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
    
    @Test("가까운 마커는 하나로 묶인다")
    func mergesNearbyAnnotations() {
        let clusters = SpaceClusterer.cluster([
            annotation(lat: 36.0190, lng: 129.3435),
            annotation(lat: 36.0191, lng: 129.3436)
        ], in: wideSpan)
        
        #expect(clusters.count == 1)
        #expect(clusters.first?.count == 2)
        #expect(clusters.first?.isSingle == false)
    }
    
    @Test("확대하면 묶였던 마커가 나뉜다")
    func splitsWhenZoomedIn() {
        let annotations = [
            annotation(lat: 36.0190, lng: 129.3435),
            annotation(lat: 36.0290, lng: 129.3535)
        ]
        
        #expect(SpaceClusterer.cluster(annotations, in: wideSpan).count == 1)
        #expect(SpaceClusterer.cluster(annotations, in: tightSpan).count == 2)
    }
    
    @Test("멀리 떨어진 마커는 따로 표시된다")
    func keepsDistantAnnotationsSeparate() {
        let clusters = SpaceClusterer.cluster([
            annotation(lat: 36.0190, lng: 129.3435),
            annotation(lat: 37.5665, lng: 126.9780)
        ], in: wideSpan)
        
        #expect(clusters.count == 2)
        #expect(clusters.allSatisfy { $0.isSingle })
    }
    
    @Test("한 구조에 속한 방들은 마커 1개로만 표시된다")
    func showsOneMarkerPerStructure() {
        let structureID = UUID()
        let annotations = [
            annotation(lat: 36.0190, lng: 129.3435, structureID: structureID),
            annotation(lat: 37.0000, lng: 128.0000, structureID: structureID),
            annotation(lat: 35.0000, lng: 127.0000)
        ]
        
        let deduplicated = SpaceClusterer.deduplicateStructures(annotations)
        
        #expect(deduplicated.count == 2)
        //대표는 목록에서 처음 만난 방이다
        #expect(deduplicated.first?.coordinate.latitude == 36.0190)
    }
    
    @Test("묶음의 좌표는 속한 마커들의 평균이다")
    func clusterUsesAverageCoordinate() {
        let coordinate = SpaceClusterer.averageCoordinate(of: [
            annotation(lat: 36.0, lng: 129.0),
            annotation(lat: 38.0, lng: 131.0)
        ])
        
        #expect(coordinate.latitude == 37.0)
        #expect(coordinate.longitude == 130.0)
    }
    
    @Test("저장된 공간이 모두 들어오는 영역을 구한다")
    func boundingRegionCoversAllAnnotations() throws {
        let region = try #require(SpaceClusterer.boundingRegion(for: [
            annotation(lat: 36.0, lng: 129.0),
            annotation(lat: 37.0, lng: 130.0)
        ]))
        
        #expect(region.center.latitude == 36.5)
        #expect(region.center.longitude == 129.5)
        //가장자리에 붙지 않도록 여유가 들어간다
        #expect(region.span.latitudeDelta > 1.0)
    }
    
    @Test("마커가 없으면 영역도 없다")
    func boundingRegionIsNilWhenEmpty() {
        let region = SpaceClusterer.boundingRegion(for: [])
        
        #expect(region == nil)
        #expect(SpaceClusterer.cluster([], in: wideSpan).isEmpty)
    }
}
