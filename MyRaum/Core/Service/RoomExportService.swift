//
//  RoomExportService.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import RoomPlan

//내보내기가 끝난 스캔 결과
struct ExportedRoom {
    //Documents/Models 아래에 저장된 USDZ 파일 이름
    let fileName: String
    //목록·지도용 썸네일 PNG
    let thumbnailData: Data?
    //가구·면적·방 종류
    let metrics: RoomMetrics
}

//현재 스캔 결과를 USDZ로 내보내고 파생 데이터를 함께 만들어 주는 역할
protocol RoomExporting {
    func exportCurrentScan(id: UUID) throws -> ExportedRoom
    //누적된 방들을 CapturedStructure로 병합해 "집 전체" 모델을 만드는 함수 (8.1)
    //방이 2개 미만이거나 병합에 실패하면 nil
    func exportMergedStructure(id: UUID) async -> String?
}

enum RoomExportError: Error {
    case noCapturedRoom
}

//스캐너·파일 저장소·썸네일 렌더러를 묶어 내보내기 한 번을 처리하는 구현체
final class RoomExportService: RoomExporting {
    private let scanner: any RoomScanning
    private let modelFileStore: any ModelFileStoring
    private let thumbnailRenderer: any ThumbnailRendering
    private let thumbnailSize = CGSize(width: 512, height: 512)
    
    init(
        scanner: any RoomScanning,
        modelFileStore: any ModelFileStoring,
        thumbnailRenderer: any ThumbnailRendering
    ) {
        self.scanner = scanner
        self.modelFileStore = modelFileStore
        self.thumbnailRenderer = thumbnailRenderer
    }
    
    func exportCurrentScan(id: UUID) throws -> ExportedRoom {
        guard let room = scanner.capturedRoom else {
            throw RoomExportError.noCapturedRoom
        }
        
        let fileName = try modelFileStore.export(room, id: id)
        
        //USDZ를 오프스크린으로 렌더해 썸네일을 만든다. 실패해도 저장 자체는 진행한다
        var thumbnailData: Data?
        if let url = modelFileStore.url(forFileName: fileName) {
            thumbnailData = thumbnailRenderer.renderThumbnail(of: url, size: thumbnailSize)
        }
        
        return ExportedRoom(
            fileName: fileName,
            thumbnailData: thumbnailData,
            metrics: RoomAnalyzer.metrics(from: room)
        )
    }
    
    //여러 방을 하나의 구조로 병합해 내보내는 함수
    //병합에 실패해도 각 방은 이미 따로 저장되어 있으므로 nil을 돌려주고 넘어간다
    func exportMergedStructure(id: UUID) async -> String? {
        let rooms = scanner.capturedRooms
        guard rooms.count >= 2 else { return nil }
        
        do {
            let builder = StructureBuilder(options: [.beautifyObjects])
            let structure = try await builder.capturedStructure(from: rooms)
            
            return try modelFileStore.exportStructure(structure, id: id)
        } catch {
            print("Failed to merge captured structure: \(error)")
            return nil
        }
    }
}
