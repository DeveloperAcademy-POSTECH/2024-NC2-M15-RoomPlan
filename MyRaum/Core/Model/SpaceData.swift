//
//  SpaceData.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI
import SwiftData

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
