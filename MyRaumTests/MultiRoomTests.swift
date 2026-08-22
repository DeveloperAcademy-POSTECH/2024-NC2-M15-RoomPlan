//
//  MultiRoomTests.swift
//  MyRaumTests
//
//  Created by Yune Cho on 8/22/26.
//

import Testing
import Foundation
@testable import MyRaum

//MultiRoom 스캔·저장 동작을 확인하는 테스트 (D-04, 8.1)
@MainActor
struct MultiRoomTests {
    private func makeViewModel(
        scanner: FakeRoomScanner = FakeRoomScanner(),
        repository: InMemorySpaceRepository,
        exporter: FakeRoomExporter
    ) -> ScanFlowViewModel {
        ScanFlowViewModel(
            scanner: scanner,
            locationService: FakeLocationService(),
            spaceRepository: repository,
            roomExporter: exporter,
            modelFileStore: FakeModelFileStore()
        )
    }
    
    @Test("방을 하나만 스캔하면 구조로 묶지 않는다")
    func singleRoomHasNoStructure() {
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(repository: repository, exporter: FakeRoomExporter(result: makeExportedRoom()))
        
        viewModel.finishScanning()
        viewModel.endEditingComment(with: "작업실")
        viewModel.saveSpaceData()
        
        #expect(repository.spaces.count == 1)
        #expect(repository.spaces.first?.structureID == nil)
        #expect(repository.spaces.first?.structureOrder == nil)
    }
    
    @Test("방 추가하기를 누르면 캡쳐 단계로 돌아가고 입력값이 초기화된다")
    func addAnotherRoomResetsEditor() {
        let scanner = FakeRoomScanner()
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(
            scanner: scanner,
            repository: repository,
            exporter: FakeRoomExporter(result: makeExportedRoom())
        )
        viewModel.finishScanning()
        viewModel.endEditingComment(with: "거실")
        
        viewModel.addAnotherRoom()
        
        #expect(viewModel.currentStep == .capture)
        #expect(viewModel.comment == "")
        #expect(viewModel.doneScanning == false)
        #expect(viewModel.structureID != nil)
        #expect(viewModel.roomCountInStructure == 2)
        //다음 방을 스캔해도 앞 방의 결과가 지워지지 않도록 보관한다
        #expect(scanner.keepForStructureCallCount == 1)
        //아직 저장은 하지 않는다
        #expect(repository.spaces.isEmpty)
    }
    
    @Test("여러 방을 스캔하면 같은 구조로 순서대로 저장된다")
    func multipleRoomsShareStructure() {
        let repository = InMemorySpaceRepository()
        let viewModel = makeViewModel(repository: repository, exporter: FakeRoomExporter(result: makeExportedRoom()))
        
        viewModel.finishScanning()
        viewModel.endEditingComment(with: "거실")
        viewModel.addAnotherRoom()
        
        viewModel.finishScanning()
        viewModel.endEditingComment(with: "침실")
        viewModel.saveSpaceData()
        
        #expect(repository.spaces.count == 2)
        
        let structureIDs = Set(repository.spaces.compactMap(\.structureID))
        #expect(structureIDs.count == 1)
        
        let ordered = repository.spaces.sorted { ($0.structureOrder ?? 0) < ($1.structureOrder ?? 0) }
        #expect(ordered.map(\.comment) == ["거실", "침실"])
        #expect(ordered.map(\.structureOrder) == [0, 1])
        //방마다 자기 모델 파일을 갖는다
        #expect(Set(ordered.compactMap(\.modelFileName)).count == 2)
    }
    
    @Test("방이 2개 이상이면 병합된 구조 모델을 만든다")
    func mergesStructureModel() async throws {
        let repository = InMemorySpaceRepository()
        let exporter = FakeRoomExporter(result: makeExportedRoom())
        exporter.mergedStructureFileName = "structure.usdz"
        let viewModel = makeViewModel(repository: repository, exporter: exporter)
        
        viewModel.finishScanning()
        viewModel.addAnotherRoom()
        viewModel.finishScanning()
        viewModel.saveSpaceData()
        
        try await waitUntil { exporter.mergeCallCount == 1 }
        try await waitUntil {
            repository.spaces.contains { $0.structureModelFileName == "structure.usdz" }
        }
        
        //병합 모델은 대표 방(순서 0)에만 붙는다
        let representative = repository.spaces.first { $0.structureOrder == 0 }
        #expect(representative?.structureModelFileName == "structure.usdz")
    }
    
    @Test("방이 하나뿐이면 병합을 시도하지 않는다")
    func doesNotMergeSingleRoom() async throws {
        let repository = InMemorySpaceRepository()
        let exporter = FakeRoomExporter(result: makeExportedRoom())
        let viewModel = makeViewModel(repository: repository, exporter: exporter)
        
        viewModel.finishScanning()
        viewModel.saveSpaceData()
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(exporter.mergeCallCount == 0)
    }
}

//보관함의 구조 묶기를 확인하는 테스트 (8.1)
@MainActor
struct SpaceGroupingTests {
    private func makeRoom(comment: String, structureID: UUID?, order: Int?) -> SpaceData {
        SpaceData(
            createdAt: .now,
            comment: comment,
            latitude: 0,
            longitude: 0,
            storageKind: .usdz,
            structureID: structureID,
            structureOrder: order,
            syncState: .pending
        )
    }
    
    @Test("구조에 속한 방들은 한 칸으로 묶인다")
    func groupsStructureIntoOneCell() {
        let structureID = UUID()
        let groups = SpaceGrouping.group([
            makeRoom(comment: "거실", structureID: structureID, order: 0),
            makeRoom(comment: "침실", structureID: structureID, order: 1),
            makeRoom(comment: "카페", structureID: nil, order: nil)
        ])
        
        #expect(groups.count == 2)
        #expect(groups[0].isStructure == true)
        #expect(groups[0].roomCount == 2)
        #expect(groups[1].isStructure == false)
    }
    
    @Test("구조 안의 방은 스캔한 순서대로 정렬된다")
    func sortsRoomsByStructureOrder() throws {
        let structureID = UUID()
        //목록에는 순서가 뒤섞여 들어온다
        let groups = SpaceGrouping.group([
            makeRoom(comment: "침실", structureID: structureID, order: 1),
            makeRoom(comment: "거실", structureID: structureID, order: 0)
        ])
        
        let group = try #require(groups.first)
        #expect(group.rooms.map(\.comment) == ["거실", "침실"])
        #expect(group.representative?.comment == "거실")
    }
    
    @Test("구조가 없으면 방 하나가 그대로 한 칸이 된다")
    func singleRoomsStayAsIs() {
        let groups = SpaceGrouping.group([
            makeRoom(comment: "작업실", structureID: nil, order: nil),
            makeRoom(comment: "카페", structureID: nil, order: nil)
        ])
        
        #expect(groups.count == 2)
        #expect(groups.allSatisfy { $0.isStructure == false })
    }
    
    @Test("빈 목록은 빈 결과를 돌려준다")
    func handlesEmptyInput() {
        #expect(SpaceGrouping.group([]).isEmpty)
    }
}
