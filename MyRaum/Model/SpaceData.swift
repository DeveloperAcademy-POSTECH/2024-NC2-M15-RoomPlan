//
//  SpaceData.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI
import SwiftData
import CoreLocation

//이전 버전에서 3D 모델을 이미지로 저장하던 공간 카드 (새 카드는 SpaceRecord로 저장)
//기존 사용자의 데이터가 유지되어야 하므로 저장 프로퍼티를 변경할 때는 VersionedSchema와 마이그레이션 플랜을 함께 추가해야 함
@Model
final class SpaceData: Identifiable {
    var id: UUID
    var date: String
    var comment: String
    @Attribute(.externalStorage) var model: Data
    @Attribute(.externalStorage) var background: Data
    var latitude: Double
    var longitude: Double

    init(id: UUID, date: String, comment: String, model: Data, background: Data, latitude: Double, longitude: Double) {
        self.id = id
        self.date = date
        self.comment = comment
        self.model = model
        self.background = background
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension SpaceData {
    //누끼 처리된 3D 모델 이미지
    var modelImage: UIImage? {
        UIImage(data: model)
    }

    var backgroundImage: UIImage? {
        UIImage(data: background)
    }

    //위치 권한이 없어서 위치 정보를 받지 못한 경우 (0, 0)으로 저장되어 있으므로 nil로 처리
    var coordinate: CLLocationCoordinate2D? {
        guard latitude != 0 || longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension ModelContext {
    //SwiftData에 공간 정보를 저장하는 함수
    func addSpace(space: SpaceData) -> Bool {
        do {
            self.insert(space)
            try self.save()
        } catch {
            print("Failed to save data")
            return false
        }
        return true
    }

    //SwiftData에서 데이터를 삭제하는 함수
    func deleteSpace(space: SpaceData) {
        do {
            self.delete(space)
            try self.save()
        } catch {
            print("Failed to save data")
        }
    }
}
