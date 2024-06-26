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
