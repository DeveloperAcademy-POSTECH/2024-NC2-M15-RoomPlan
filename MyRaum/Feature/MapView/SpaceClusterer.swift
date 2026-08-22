//
//  SpaceClusterer.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import CoreLocation
import MapKit

//지도에 찍을 항목 하나
struct SpaceAnnotation: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    //구조에 속한 방이면 구조 식별자. 지도에서는 구조당 마커 1개만 그린다
    let structureID: UUID?
    
    static func == (lhs: SpaceAnnotation, rhs: SpaceAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

//같은 자리에 모인 마커 묶음
struct SpaceCluster: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let annotations: [SpaceAnnotation]
    
    var count: Int { annotations.count }
    var isSingle: Bool { annotations.count == 1 }
    var first: SpaceAnnotation? { annotations.first }
}

//가까이 있는 마커를 묶어 주는 역할
//SwiftUI Map에는 클러스터링이 없으므로 보이는 영역 기준으로 직접 묶는다
enum SpaceClusterer {
    //화면에서 이 비율보다 가까우면 같은 묶음으로 본다 (보이는 영역의 8%)
    static let mergeRatio: Double = 0.08
    
    //구조에 속한 방은 대표 1개만 남기는 함수 (Phase 8 — 지도에서는 구조당 마커 1개)
    static func deduplicateStructures(_ annotations: [SpaceAnnotation]) -> [SpaceAnnotation] {
        var seenStructures = Set<UUID>()
        var result: [SpaceAnnotation] = []
        
        for annotation in annotations {
            guard let structureID = annotation.structureID else {
                result.append(annotation)
                continue
            }
            
            if seenStructures.contains(structureID) == false {
                seenStructures.insert(structureID)
                result.append(annotation)
            }
        }
        
        return result
    }
    
    //보이는 영역을 기준으로 마커를 묶는 함수
    static func cluster(_ annotations: [SpaceAnnotation], in span: MKCoordinateSpan) -> [SpaceCluster] {
        let deduplicated = deduplicateStructures(annotations)
        guard deduplicated.isEmpty == false else { return [] }
        
        let latitudeThreshold = span.latitudeDelta * mergeRatio
        let longitudeThreshold = span.longitudeDelta * mergeRatio
        
        var clusters: [[SpaceAnnotation]] = []
        
        for annotation in deduplicated {
            //이미 만들어진 묶음 중 가까운 곳이 있으면 합친다
            if let index = clusters.firstIndex(where: { group in
                guard let representative = group.first else { return false }
                return abs(representative.coordinate.latitude - annotation.coordinate.latitude) <= latitudeThreshold
                    && abs(representative.coordinate.longitude - annotation.coordinate.longitude) <= longitudeThreshold
            }) {
                clusters[index].append(annotation)
            } else {
                clusters.append([annotation])
            }
        }
        
        return clusters.compactMap { group in
            guard let first = group.first else { return nil }
            
            return SpaceCluster(
                id: first.id,
                coordinate: averageCoordinate(of: group),
                annotations: group
            )
        }
    }
    
    //묶음의 중심 좌표를 구하는 함수
    static func averageCoordinate(of annotations: [SpaceAnnotation]) -> CLLocationCoordinate2D {
        guard annotations.isEmpty == false else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        
        let count = Double(annotations.count)
        let latitude = annotations.reduce(0.0) { $0 + $1.coordinate.latitude } / count
        let longitude = annotations.reduce(0.0) { $0 + $1.coordinate.longitude } / count
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    //저장된 공간이 모두 들어오는 영역을 구하는 함수
    static func boundingRegion(for annotations: [SpaceAnnotation]) -> MKCoordinateRegion? {
        guard annotations.isEmpty == false else { return nil }
        
        let latitudes = annotations.map(\.coordinate.latitude)
        let longitudes = annotations.map(\.coordinate.longitude)
        
        guard let minLatitude = latitudes.min(), let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(), let maxLongitude = longitudes.max() else {
            return nil
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        //마커가 가장자리에 붙지 않도록 여유를 준다
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.4, 0.01),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.4, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
