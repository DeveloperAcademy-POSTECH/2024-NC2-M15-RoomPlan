//
//  SyncQueueTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//업로드 큐와 원격 복원 동작을 확인하는 테스트 (PRD 6-B)
@MainActor
struct SyncQueueTests {
    //모델 파일이 실제로 있어야 업로드가 진행되므로 임시 파일을 만들어 둔다
    private func makeFileStore() throws -> FakeModelFileStore {
        let store = FakeModelFileStore()
        let url = FileManager.default.temporaryDirectory
            .appending(path: "sync-\(UUID().uuidString).usdz")
        try Data([0x55, 0x53, 0x44, 0x5A]).write(to: url)
        store.urlForAnyFile = url
        return store
    }
    
    private func makeQueue(
        repository: InMemorySpaceRepository,
        remote: FakeRemoteSpaceRepository,
        fileStore: FakeModelFileStore,
        auth: FakeAuthService? = nil
    ) -> SyncQueue {
        SyncQueue(
            localRepository: repository,
            remoteRepository: remote,
            modelFileStore: fileStore,
            authService: auth ?? FakeAuthService(currentUserID: "user")
        )
    }
    
    @Test("pending 상태의 신규 공간만 업로드 대상으로 잡힌다")
    func onlyPendingUsdzSpacesAreQueued() {
        let repository = InMemorySpaceRepository()
        repository.save(makeSpaceData(comment: "신규", storageKind: .usdz))
        //레거시 카드는 업로드 대상이 아니다 (D-06, 6B.10)
        repository.save(makeSpaceData(comment: "레거시", storageKind: .legacyImage))
        
        let pending = repository.fetchPendingUpload()
        
        #expect(pending.count == 1)
        #expect(pending.first?.comment == "신규")
    }
    
    @Test("업로드에 성공하면 synced로 바뀌고 remoteID가 채워진다")
    func successfulUploadMarksSynced() async throws {
        let repository = InMemorySpaceRepository()
        let space = makeSpaceData(comment: "작업실", storageKind: .usdz)
        repository.save(space)
        
        let remote = FakeRemoteSpaceRepository()
        let queue = makeQueue(repository: repository, remote: remote, fileStore: try makeFileStore())
        
        queue.startIfNeeded()
        try await waitUntil { space.sync == .synced }
        
        #expect(space.sync == .synced)
        #expect(space.remoteID == space.id.uuidString)
        #expect(remote.uploadedIDs == [space.id])
    }
    
    @Test("업로드에 실패하면 failed로 남아 다음에 다시 시도된다")
    func failedUploadStaysQueued() async throws {
        let repository = InMemorySpaceRepository()
        let space = makeSpaceData(storageKind: .usdz)
        repository.save(space)
        
        let remote = FakeRemoteSpaceRepository()
        remote.uploadError = RemoteSpaceError.notConfigured
        let queue = makeQueue(repository: repository, remote: remote, fileStore: try makeFileStore())
        
        queue.startIfNeeded()
        try await waitUntil { space.sync == .failed }
        queue.cancel()
        
        #expect(space.sync == .failed)
        #expect(space.remoteID == nil)
        //failed도 다시 업로드 대상으로 잡혀야 한다
        #expect(repository.fetchPendingUpload().isEmpty == false)
    }
    
    @Test("일시적으로 실패해도 재시도해서 결국 업로드된다")
    func retriesUntilSuccess() async throws {
        let repository = InMemorySpaceRepository()
        let space = makeSpaceData(storageKind: .usdz)
        repository.save(space)
        
        let remote = FakeRemoteSpaceRepository()
        remote.failuresBeforeSuccess = 1
        let queue = makeQueue(repository: repository, remote: remote, fileStore: try makeFileStore())
        
        queue.startIfNeeded()
        try await waitUntil(timeout: 10) { space.sync == .synced }
        
        #expect(space.sync == .synced)
    }
    
    @Test("로그인하지 않았으면 업로드를 시작하지 않는다")
    func doesNotStartWhenSignedOut() async throws {
        let repository = InMemorySpaceRepository()
        let space = makeSpaceData(storageKind: .usdz)
        repository.save(space)
        
        let remote = FakeRemoteSpaceRepository()
        let queue = makeQueue(
            repository: repository,
            remote: remote,
            fileStore: try makeFileStore(),
            auth: FakeAuthService(currentUserID: nil)
        )
        
        queue.startIfNeeded()
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(remote.uploadedIDs.isEmpty)
        #expect(space.sync == .pending)
    }
    
    @Test("모델 파일이 사라졌으면 failed로 표시하고 넘어간다")
    func missingModelFileFails() async throws {
        let repository = InMemorySpaceRepository()
        let space = makeSpaceData(storageKind: .usdz)
        repository.save(space)
        
        let fileStore = FakeModelFileStore()
        fileStore.urlForAnyFile = nil
        let remote = FakeRemoteSpaceRepository()
        let queue = makeQueue(repository: repository, remote: remote, fileStore: fileStore)
        
        queue.startIfNeeded()
        try await waitUntil { space.sync == .failed }
        queue.cancel()
        
        #expect(remote.uploadedIDs.isEmpty)
    }
}

//원격 복원 동작을 확인하는 테스트 (6B.7)
@MainActor
struct RemoteRestoreServiceTests {
    private func makeRemoteSpace(comment: String) -> RemoteSpace {
        RemoteSpace(
            id: UUID(),
            owner: UUID(),
            comment: comment,
            createdAt: Date(timeIntervalSince1970: 1_787_000_000),
            latitude: 36.0190,
            longitude: 129.3435,
            storagePath: "owner/space.usdz",
            thumbnailPath: "owner/space.png",
            furniture: nil,
            floorAreaSqM: 12.0,
            roomTypeGuess: "bedroom",
            structureId: nil,
            structureOrder: nil,
            showsDate: true,
            isPublic: false
        )
    }
    
    @Test("로컬에 없는 원격 공간을 내려받아 복원한다")
    func restoresMissingSpaces() async {
        let repository = InMemorySpaceRepository()
        let remote = FakeRemoteSpaceRepository()
        remote.remoteSpaces = [makeRemoteSpace(comment: "작업실"), makeRemoteSpace(comment: "침실")]
        let fileStore = FakeModelFileStore()
        
        let service = RemoteRestoreService(
            localRepository: repository,
            remoteRepository: remote,
            modelFileStore: fileStore
        )
        
        let restored = await service.restoreMissingSpaces()
        
        #expect(restored == 2)
        #expect(repository.spaces.count == 2)
        #expect(fileStore.writtenIDs.count == 2)
        //복원된 공간은 이미 서버에 있으므로 다시 올리지 않는다
        #expect(repository.spaces.allSatisfy { $0.sync == .synced })
        #expect(repository.fetchPendingUpload().isEmpty)
    }
    
    @Test("이미 로컬에 있는 공간은 다시 내려받지 않는다")
    func skipsAlreadyPresentSpaces() async {
        let existing = makeRemoteSpace(comment: "작업실")
        let repository = InMemorySpaceRepository()
        repository.save(SpaceData(
            id: existing.id,
            createdAt: existing.createdAt,
            comment: existing.comment,
            latitude: 0,
            longitude: 0,
            storageKind: .usdz,
            syncState: .synced
        ))
        
        let remote = FakeRemoteSpaceRepository()
        remote.remoteSpaces = [existing]
        let fileStore = FakeModelFileStore()
        
        let service = RemoteRestoreService(
            localRepository: repository,
            remoteRepository: remote,
            modelFileStore: fileStore
        )
        
        let restored = await service.restoreMissingSpaces()
        
        #expect(restored == 0)
        #expect(fileStore.writtenIDs.isEmpty)
    }
}

//조건이 만족될 때까지 기다리는 헬퍼
@MainActor
func waitUntil(timeout: Double = 5, _ condition: () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    
    while Date() < deadline {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(50))
    }
    
    Issue.record("조건이 \(timeout)초 안에 만족되지 않았습니다.")
}
