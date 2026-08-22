//
//  SpaceData.swift
//  MyRaum
//
//  Created by Yune Cho on 6/14/24.
//

import SwiftUI
import SwiftData

//앱이 사용하는 현재 스키마
typealias SpaceData = SpaceSchemaV2.SpaceData

//2.0 스키마. USDZ 저장·MultiRoom·서버 동기화 필드를 포함한다
enum SpaceSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    
    static var models: [any PersistentModel.Type] { [SpaceData.self] }
    
    @Model
    final class SpaceData: Identifiable {
        var id: UUID
        //V1의 date(String)를 파싱한 값. 정렬·필터를 위해 Date로 보관
        var createdAt: Date = Date.distantPast
        var comment: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        
        //저장 방식 구분 — 기존 레코드는 마이그레이션 시 legacyImage가 된다
        var storageKind: String = SpaceStorageKind.legacyImage.rawValue
        
        //legacyImage 전용 (기존 사용자)
        //V1의 model 컬럼을 그대로 이어받는다
        @Attribute(.externalStorage, originalName: "model") var legacyModelImage: Data?
        @Attribute(.externalStorage) var background: Data?
        //V1의 date 문자열 원본. 파싱에 실패해도 표시가 깨지지 않도록 보존한다
        @Attribute(originalName: "date") var legacyDateText: String?
        
        //usdz 전용 (신규)
        //Documents/Models/{uuid}.usdz  (.parametric 단독)
        var modelFileName: String?
        //지도 마커·목록용
        @Attribute(.externalStorage) var thumbnail: Data?
        
        //MultiRoom (D-04) — 여러 방이 하나의 구조에 속할 수 있음
        var structureID: UUID?
        var structureOrder: Int?
        
        //RoomPlan 파생 데이터
        var furnitureJSON: String?
        var floorAreaSqM: Double?
        var roomTypeGuess: String?
        
        //공개·동기화 상태 (D-06 — 신규 데이터는 전량 업로드, 토글은 공개 여부만 제어)
        var isPublic: Bool = false
        var remoteID: String?
        var syncState: String = SpaceSyncState.localOnly.rawValue
        
        init(
            id: UUID = UUID(),
            createdAt: Date,
            comment: String,
            latitude: Double,
            longitude: Double,
            storageKind: SpaceStorageKind,
            legacyModelImage: Data? = nil,
            background: Data? = nil,
            legacyDateText: String? = nil,
            modelFileName: String? = nil,
            thumbnail: Data? = nil,
            structureID: UUID? = nil,
            structureOrder: Int? = nil,
            furnitureJSON: String? = nil,
            floorAreaSqM: Double? = nil,
            roomTypeGuess: String? = nil,
            isPublic: Bool = false,
            remoteID: String? = nil,
            syncState: SpaceSyncState
        ) {
            self.id = id
            self.createdAt = createdAt
            self.comment = comment
            self.latitude = latitude
            self.longitude = longitude
            self.storageKind = storageKind.rawValue
            self.legacyModelImage = legacyModelImage
            self.background = background
            self.legacyDateText = legacyDateText
            self.modelFileName = modelFileName
            self.thumbnail = thumbnail
            self.structureID = structureID
            self.structureOrder = structureOrder
            self.furnitureJSON = furnitureJSON
            self.floorAreaSqM = floorAreaSqM
            self.roomTypeGuess = roomTypeGuess
            self.isPublic = isPublic
            self.remoteID = remoteID
            self.syncState = syncState.rawValue
        }
    }
}

extension SpaceData {
    //문자열로 저장된 값을 타입 안전하게 다루기 위한 접근자
    var kind: SpaceStorageKind {
        SpaceStorageKind(rawValue: storageKind) ?? .legacyImage
    }
    
    var sync: SpaceSyncState {
        SpaceSyncState(rawValue: syncState) ?? .localOnly
    }
    
    var furniture: [CapturedFurniture] {
        [CapturedFurniture].decoded(from: furnitureJSON)
    }
    
    var roomType: RoomTypeGuess {
        RoomTypeGuess(rawValue: roomTypeGuess ?? "") ?? .unknown
    }
    
    //카드 목록·지도 마커에 쓰는 미리보기 이미지
    //USDZ 카드는 썸네일을, 레거시 카드는 누끼 이미지를 사용한다
    var previewImageData: Data? {
        switch kind {
        case .usdz: return thumbnail
        case .legacyImage: return legacyModelImage
        }
    }
    
    //카드에 표시할 날짜 문자열
    //원본 문자열이 남아 있으면 그대로 쓰고, 없으면 createdAt을 포맷한다
    var displayDate: String {
        if let legacyDateText, !legacyDateText.isEmpty {
            return legacyDateText
        }
        return createdAt.spaceCardFormatted
    }
}
