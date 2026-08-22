//
//  SpaceSchemaV1.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import SwiftData

//1.0.x에서 사용하던 스키마. 마이그레이션 기준점으로만 보존한다
enum SpaceSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    
    static var models: [any PersistentModel.Type] { [SpaceData.self] }
    
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
}
