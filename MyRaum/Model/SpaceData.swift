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
    func addSpace(date: Date, comment: String, model: UIImage? = nil, background: UIImage? = nil, latitude: Double, longitude: Double) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        let savedDate = formatter.string(from: date)
        
        if let model, let background {
            let newSpace = SpaceData(
                id: UUID(),
                date: savedDate,
                comment: comment,
                model: model.pngData()!,
                background: background.pngData()!,
                latitude: latitude,
                longitude: longitude
            )
                
            do {
                self.insert(newSpace)
                try self.save()
            } catch {
                print("Failed to save data")
            }
            
            return true
        } else {
            return false
        }
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
