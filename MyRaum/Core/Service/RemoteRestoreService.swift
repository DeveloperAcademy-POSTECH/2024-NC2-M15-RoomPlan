//
//  RemoteRestoreService.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//기기를 바꾼 뒤 로그인하면 서버의 공간을 로컬로 내려받는 역할 (6B.7)
//레거시 카드는 서버에 없으므로 복원 대상이 아니다 (D-06)
@Observable
@MainActor
final class RemoteRestoreService {
    private(set) var isRestoring: Bool = false
    private(set) var restoredCount: Int = 0
    
    private let localRepository: any SpaceRepository
    private let remoteRepository: any RemoteSpaceRepositoryProtocol
    private let modelFileStore: any ModelFileStoring
    
    init(
        localRepository: any SpaceRepository,
        remoteRepository: any RemoteSpaceRepositoryProtocol,
        modelFileStore: any ModelFileStoring
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.modelFileStore = modelFileStore
    }
    
    //로컬에 없는 원격 공간만 내려받는 함수
    @discardableResult
    func restoreMissingSpaces() async -> Int {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            let remoteSpaces = try await remoteRepository.fetchMySpaces()
            let existingIDs = Set(localRepository.fetchAll().map(\.id))
            let missing = remoteSpaces.filter { existingIDs.contains($0.id) == false }
            
            var restored = 0
            
            for remote in missing {
                if await restore(remote) {
                    restored += 1
                }
            }
            
            restoredCount = restored
            return restored
        } catch {
            print("Failed to restore remote spaces: \(error)")
            return 0
        }
    }
    
    //원격 공간 한 건을 로컬에 되살리는 함수
    private func restore(_ remote: RemoteSpace) async -> Bool {
        guard let storagePath = remote.storagePath else { return false }
        
        do {
            let modelData = try await remoteRepository.downloadModel(storagePath: storagePath)
            let fileName = try modelFileStore.write(modelData, id: remote.id)
            
            //썸네일은 없어도 카드가 렌더링되므로 실패해도 계속 진행한다
            var thumbnailData: Data?
            if let thumbnailPath = remote.thumbnailPath {
                thumbnailData = try? await remoteRepository.downloadThumbnail(thumbnailPath: thumbnailPath)
            }
            
            let space = SpaceData(
                id: remote.id,
                createdAt: remote.createdAt,
                comment: remote.comment,
                latitude: remote.latitude,
                longitude: remote.longitude,
                storageKind: .usdz,
                showsDate: remote.showsDate,
                modelFileName: fileName,
                thumbnail: thumbnailData,
                structureID: remote.structureId,
                structureOrder: remote.structureOrder,
                furnitureJSON: remote.furniture,
                floorAreaSqM: remote.floorAreaSqM,
                roomTypeGuess: remote.roomTypeGuess,
                isPublic: remote.isPublic,
                remoteID: remote.id.uuidString,
                syncState: .synced
            )
            
            return localRepository.save(space)
        } catch {
            print("Failed to restore space \(remote.id): \(error)")
            return false
        }
    }
}
