//
//  RemoteSpaceRepository.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import Supabase

//서버에 저장된 공간 한 건 (spaces 테이블의 행)
struct RemoteSpace: Codable, Identifiable {
    let id: UUID
    let owner: UUID
    let comment: String
    let createdAt: Date
    let latitude: Double
    let longitude: Double
    let storagePath: String?
    let thumbnailPath: String?
    let furniture: String?
    let floorAreaSqM: Double?
    let roomTypeGuess: String?
    let structureId: UUID?
    let structureOrder: Int?
    let showsDate: Bool
    let isPublic: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case comment
        case createdAt = "created_at"
        case latitude
        case longitude
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case furniture
        case floorAreaSqM = "floor_area_sq_m"
        case roomTypeGuess = "room_type_guess"
        case structureId = "structure_id"
        case structureOrder = "structure_order"
        case showsDate = "shows_date"
        case isPublic = "is_public"
    }
}

//공간을 서버에 올리고 내려받는 역할
protocol RemoteSpaceRepositoryProtocol: Sendable {
    //USDZ·썸네일·메타데이터를 올리고 서버 식별자를 리턴
    func upload(_ payload: RemoteUploadPayload) async throws -> String
    //공개 여부만 갱신한다. 원격 데이터를 지우지 않는다 (6B.9)
    func updateIsPublic(remoteID: String, isPublic: Bool) async throws
    func delete(remoteID: String) async throws
    //내 공간 목록을 가져온다 (기기 변경 후 복원용, 6B.7)
    func fetchMySpaces() async throws -> [RemoteSpace]
    //모델 파일을 내려받는다
    func downloadModel(storagePath: String) async throws -> Data
    func downloadThumbnail(thumbnailPath: String) async throws -> Data
}

//업로드에 필요한 값만 모아 둔 구조체
//SpaceData(@Model)를 액터 경계 밖으로 넘기지 않기 위해 값 타입으로 옮겨 담는다
struct RemoteUploadPayload: Sendable {
    let id: UUID
    let comment: String
    let createdAt: Date
    let latitude: Double
    let longitude: Double
    let modelData: Data
    let modelFileName: String
    let thumbnailData: Data?
    let furnitureJSON: String?
    let floorAreaSqM: Double?
    let roomTypeGuess: String?
    let structureID: UUID?
    let structureOrder: Int?
    let showsDate: Bool
    let isPublic: Bool
}

enum RemoteSpaceError: LocalizedError {
    case notConfigured
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "서버 설정이 없어 업로드할 수 없습니다."
        case .notAuthenticated:
            return "로그인이 필요합니다."
        }
    }
}

//Supabase Storage + Postgres를 사용하는 구현체 (6B.3, 6B.4)
final class SupabaseSpaceRepository: RemoteSpaceRepositoryProtocol {
    static let bucket = "space-models"
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func upload(_ payload: RemoteUploadPayload) async throws -> String {
        let userID = try await client.auth.session.user.id
        
        //사용자별 폴더로 나눠 저장해 RLS 정책과 경로 규칙을 일치시킨다
        let modelPath = "\(userID.uuidString)/\(payload.id.uuidString).usdz"
        try await client.storage
            .from(Self.bucket)
            .upload(modelPath, data: payload.modelData, options: FileOptions(contentType: "model/vnd.usdz+zip", upsert: true))
        
        var thumbnailPath: String?
        if let thumbnailData = payload.thumbnailData {
            let path = "\(userID.uuidString)/\(payload.id.uuidString).png"
            try await client.storage
                .from(Self.bucket)
                .upload(path, data: thumbnailData, options: FileOptions(contentType: "image/png", upsert: true))
            thumbnailPath = path
        }
        
        let row = RemoteSpace(
            id: payload.id,
            owner: userID,
            comment: payload.comment,
            createdAt: payload.createdAt,
            latitude: payload.latitude,
            longitude: payload.longitude,
            storagePath: modelPath,
            thumbnailPath: thumbnailPath,
            furniture: payload.furnitureJSON,
            floorAreaSqM: payload.floorAreaSqM,
            roomTypeGuess: payload.roomTypeGuess,
            structureId: payload.structureID,
            structureOrder: payload.structureOrder,
            showsDate: payload.showsDate,
            isPublic: payload.isPublic
        )
        
        try await client
            .from("spaces")
            .upsert(row)
            .execute()
        
        return payload.id.uuidString
    }
    
    //공개 여부만 바꾼다. 원격 데이터는 그대로 둔다 (6B.9)
    func updateIsPublic(remoteID: String, isPublic: Bool) async throws {
        try await client
            .from("spaces")
            .update(["is_public": isPublic])
            .eq("id", value: remoteID)
            .execute()
    }
    
    func delete(remoteID: String) async throws {
        let userID = try await client.auth.session.user.id
        
        try? await client.storage
            .from(Self.bucket)
            .remove(paths: [
                "\(userID.uuidString)/\(remoteID).usdz",
                "\(userID.uuidString)/\(remoteID).png"
            ])
        
        try await client
            .from("spaces")
            .delete()
            .eq("id", value: remoteID)
            .execute()
    }
    
    func fetchMySpaces() async throws -> [RemoteSpace] {
        let userID = try await client.auth.session.user.id
        
        return try await client
            .from("spaces")
            .select()
            .eq("owner", value: userID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func downloadModel(storagePath: String) async throws -> Data {
        try await client.storage.from(Self.bucket).download(path: storagePath)
    }
    
    func downloadThumbnail(thumbnailPath: String) async throws -> Data {
        try await client.storage.from(Self.bucket).download(path: thumbnailPath)
    }
}

//Supabase 설정이 없을 때 사용하는 대체 구현. 업로드는 실패하고 pending으로 남는다
struct UnconfiguredRemoteSpaceRepository: RemoteSpaceRepositoryProtocol {
    func upload(_ payload: RemoteUploadPayload) async throws -> String {
        throw RemoteSpaceError.notConfigured
    }
    
    func updateIsPublic(remoteID: String, isPublic: Bool) async throws {
        throw RemoteSpaceError.notConfigured
    }
    
    func delete(remoteID: String) async throws {
        throw RemoteSpaceError.notConfigured
    }
    
    func fetchMySpaces() async throws -> [RemoteSpace] {
        throw RemoteSpaceError.notConfigured
    }
    
    func downloadModel(storagePath: String) async throws -> Data {
        throw RemoteSpaceError.notConfigured
    }
    
    func downloadThumbnail(thumbnailPath: String) async throws -> Data {
        throw RemoteSpaceError.notConfigured
    }
}
