//
//  SyncQueue.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//업로드 재시도 큐 (6B.6)
//로컬 저장이 끝난 뒤 백그라운드로 업로드하고, 실패하면 지수 백오프로 다시 시도한다
//오프라인에서는 pending 상태로 남고 다음 기회에 다시 올라간다 (NFR-04)
@Observable
@MainActor
final class SyncQueue {
    //현재 업로드가 돌고 있는지
    private(set) var isSyncing: Bool = false
    //마지막 시도에서 실패한 건수
    private(set) var failedCount: Int = 0
    
    private let localRepository: any SpaceRepository
    private let remoteRepository: any RemoteSpaceRepositoryProtocol
    private let modelFileStore: any ModelFileStoring
    private let authService: any AuthProviding
    
    private var syncTask: Task<Void, Never>?
    
    //재시도 간격 (초). 마지막 값에 도달하면 더 늘리지 않는다
    private let backoffSchedule: [UInt64] = [2, 5, 15, 60, 300]
    
    init(
        localRepository: any SpaceRepository,
        remoteRepository: any RemoteSpaceRepositoryProtocol,
        modelFileStore: any ModelFileStoring,
        authService: any AuthProviding
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.modelFileStore = modelFileStore
        self.authService = authService
    }
    
    //대기 중인 업로드를 처리한다. 이미 돌고 있으면 아무것도 하지 않는다
    func startIfNeeded() {
        guard syncTask == nil else { return }
        guard authService.isAuthenticated else { return }
        
        syncTask = Task { [weak self] in
            await self?.drain()
            self?.syncTask = nil
        }
    }
    
    func cancel() {
        syncTask?.cancel()
        syncTask = nil
        isSyncing = false
    }
    
    //대기 목록을 순서대로 올리는 함수
    private func drain() async {
        isSyncing = true
        defer { isSyncing = false }
        
        var attempt = 0
        
        while Task.isCancelled == false {
            let pending = localRepository.fetchPendingUpload()
            
            guard pending.isEmpty == false else {
                failedCount = 0
                return
            }
            
            var failures = 0
            
            for space in pending {
                if Task.isCancelled { return }
                
                do {
                    try await upload(space)
                } catch {
                    print("Failed to upload space: \(error)")
                    space.syncState = SpaceSyncState.failed.rawValue
                    localRepository.saveChanges()
                    failures += 1
                }
            }
            
            failedCount = failures
            
            guard failures > 0 else { return }
            
            //실패가 남아 있으면 지수 백오프로 다시 시도한다
            let delay = backoffSchedule[min(attempt, backoffSchedule.count - 1)]
            attempt += 1
            
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
        }
    }
    
    //한 건을 올리는 함수
    private func upload(_ space: SpaceData) async throws {
        //레거시 카드는 업로드 대상이 아니다 (6B.10)
        guard space.kind == .usdz else { return }
        
        guard let modelFileName = space.modelFileName,
              let modelURL = modelFileStore.url(forFileName: modelFileName) else {
            //모델 파일이 사라졌다면 다시 시도해도 소용이 없다
            space.syncState = SpaceSyncState.failed.rawValue
            localRepository.saveChanges()
            return
        }
        
        let payload = RemoteUploadPayload(
            id: space.id,
            comment: space.comment,
            createdAt: space.createdAt,
            latitude: space.latitude,
            longitude: space.longitude,
            modelData: try Data(contentsOf: modelURL),
            modelFileName: modelFileName,
            thumbnailData: space.thumbnail,
            furnitureJSON: space.furnitureJSON,
            floorAreaSqM: space.floorAreaSqM,
            roomTypeGuess: space.roomTypeGuess,
            structureID: space.structureID,
            structureOrder: space.structureOrder,
            showsDate: space.showsDate,
            isPublic: space.isPublic
        )
        
        let remoteID = try await remoteRepository.upload(payload)
        
        space.remoteID = remoteID
        space.syncState = SpaceSyncState.synced.rawValue
        localRepository.saveChanges()
    }
}
