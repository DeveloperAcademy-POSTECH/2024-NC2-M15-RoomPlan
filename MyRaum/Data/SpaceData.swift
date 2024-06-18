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
    @Attribute(.externalStorage) var model: Data
    @Attribute(.externalStorage) var background: Data
    var comment: String
    var music: String
    
    init(id: UUID, date: String, model: Data, background: Data, comment: String, music: String) {
        self.id = id
        self.date = date
        self.model = model
        self.background = background
        self.comment = comment
        self.music = music
    }
}
