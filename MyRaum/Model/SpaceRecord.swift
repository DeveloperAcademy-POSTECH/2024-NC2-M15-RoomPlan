//
//  SpaceRecord.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI
import SwiftData
import CoreLocation

//3D 모델로 저장되는 공간 카드
//이미지로 저장되던 이전 카드(SpaceData)와는 별도의 모델로 저장해서 기존 데이터에 영향을 주지 않음
@Model
final class SpaceRecord {
    var id: UUID
    var createdAt: Date
    //보관함에서 보여줄 이름 (장소 요소의 텍스트)
    var title: String
    //RoomPlan에서 내보낸 USDZ 파일
    @Attribute(.externalStorage) var modelFile: Data
    //RoomPlan의 CapturedRoom을 JSON으로 인코딩한 원본 데이터 (추후 다른 형식으로 내보내기 위해 보관)
    @Attribute(.externalStorage) var roomData: Data?
    //사용자가 맞춘 각도로 렌더링한 3D 모델 이미지 (배경 투명)
    @Attribute(.externalStorage) var thumbnail: Data
    @Attribute(.externalStorage) var background: Data?
    var backgroundPreset: Int
    var elementsData: Data
    //인식된 가구 목록 (FurnitureCategory의 rawValue)
    var furnitureKeys: [String]
    //스캔한 위치 (위치 권한이 없으면 nil) - 카드를 수정해도 바뀌지 않음
    var latitude: Double?
    var longitude: Double?
    //썸네일을 만들 때의 카메라 위치 - 카드를 수정할 때 같은 각도로 복원하기 위해 사용
    var cameraData: Data?

    init(
        id: UUID = UUID(),
        createdAt: Date,
        title: String,
        modelFile: Data,
        roomData: Data?,
        thumbnail: Data,
        background: Data?,
        backgroundPreset: Int,
        elements: [StoryElement],
        furniture: [FurnitureCategory],
        coordinate: CLLocationCoordinate2D?,
        cameraPose: CameraPose?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.modelFile = modelFile
        self.roomData = roomData
        self.thumbnail = thumbnail
        self.background = background
        self.backgroundPreset = backgroundPreset
        self.elementsData = (try? JSONEncoder().encode(elements)) ?? Data()
        self.furnitureKeys = furniture.map(\.rawValue)
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
        self.cameraData = cameraPose.flatMap { try? JSONEncoder().encode($0) }
    }
}

extension SpaceRecord {
    var elements: [StoryElement] {
        get { (try? JSONDecoder().decode([StoryElement].self, from: elementsData)) ?? [] }
        set { elementsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    var cameraPose: CameraPose? {
        get { cameraData.flatMap { try? JSONDecoder().decode(CameraPose.self, from: $0) } }
        set { cameraData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    var furniture: [FurnitureCategory] {
        furnitureKeys.compactMap(FurnitureCategory.init(rawValue:))
    }

    var thumbnailImage: UIImage? {
        UIImage(data: thumbnail)
    }

    var backgroundImage: UIImage? {
        background.flatMap(UIImage.init(data:))
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    //USDZ 파일을 공유하거나 SceneKit으로 열기 위해 임시 파일로 저장
    func writeModelFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MyRaum-\(createdAt.cardDateString)-\(id.uuidString.prefix(4))")
            .appendingPathExtension("usdz")
        if !FileManager.default.fileExists(atPath: url.path) {
            try modelFile.write(to: url)
        }
        return url
    }
}

extension ModelContext {
    func addRecord(_ record: SpaceRecord) -> Bool {
        do {
            self.insert(record)
            try self.save()
        } catch {
            print("Failed to save data")
            return false
        }
        return true
    }

    //수정한 내용을 저장
    func saveChanges() -> Bool {
        do {
            try self.save()
        } catch {
            print("Failed to save data")
            return false
        }
        return true
    }
    
    //여러 공간 카드를 한 번에 삭제
    func deleteRecords(_ records: [SpaceRecord]) {
        do {
            records.forEach { self.delete($0) }
            try self.save()
        } catch {
            print("Failed to delete data")
        }
    }
    
    func deleteRecord(_ record: SpaceRecord) {
        do {
            self.delete(record)
            try self.save()
        } catch {
            print("Failed to delete data")
        }
    }
}
