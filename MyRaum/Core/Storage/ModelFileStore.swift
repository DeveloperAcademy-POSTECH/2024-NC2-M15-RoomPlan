//
//  ModelFileStore.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation
import RoomPlan

//USDZ 모델 파일의 저장 위치와 입출력을 담당하는 역할
protocol ModelFileStoring {
    //스캔 결과를 USDZ로 내보내고 저장된 파일 이름을 리턴
    func export(_ room: CapturedRoom, id: UUID) throws -> String
    //병합된 구조를 USDZ로 내보내고 저장된 파일 이름을 리턴
    func exportStructure(_ structure: CapturedStructure, id: UUID) throws -> String
    //내려받은 USDZ 데이터를 저장하고 파일 이름을 리턴
    func write(_ data: Data, id: UUID) throws -> String
    //파일 이름으로 실제 경로를 구함
    func url(forFileName fileName: String) -> URL?
    //모델 파일을 삭제
    func delete(fileName: String)
}

//Documents/Models 아래에 USDZ 파일을 저장하는 구현체
final class ModelFileStore: ModelFileStoring {
    private let directoryName = "Models"
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    //모델을 보관하는 폴더. 없으면 만들어서 리턴한다
    private func modelsDirectory() throws -> URL {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ModelFileStoreError.documentsDirectoryUnavailable
        }
        
        let directory = documents.appending(path: directoryName)
        
        if fileManager.fileExists(atPath: directory.path()) == false {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        return directory
    }
    
    //스캔 결과를 .parametric 옵션으로 내보내는 함수 (D-03)
    func export(_ room: CapturedRoom, id: UUID) throws -> String {
        let fileName = "\(id.uuidString).usdz"
        let destination = try modelsDirectory().appending(path: fileName)
        
        try room.export(to: destination, exportOptions: .parametric)
        
        return fileName
    }
    
    //병합된 구조를 내보내는 함수. 방 단위 파일과 구분하기 위해 접두어를 붙인다
    func exportStructure(_ structure: CapturedStructure, id: UUID) throws -> String {
        let fileName = "structure-\(id.uuidString).usdz"
        let destination = try modelsDirectory().appending(path: fileName)
        
        try structure.export(to: destination, exportOptions: .parametric)
        
        return fileName
    }
    
    //서버에서 내려받은 모델을 저장하는 함수
    func write(_ data: Data, id: UUID) throws -> String {
        let fileName = "\(id.uuidString).usdz"
        let destination = try modelsDirectory().appending(path: fileName)
        
        try data.write(to: destination, options: .atomic)
        
        return fileName
    }
    
    func url(forFileName fileName: String) -> URL? {
        guard let directory = try? modelsDirectory() else { return nil }
        
        let url = directory.appending(path: fileName)
        return fileManager.fileExists(atPath: url.path()) ? url : nil
    }
    
    func delete(fileName: String) {
        guard let url = url(forFileName: fileName) else { return }
        
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("Failed to delete model file: \(error)")
        }
    }
}

enum ModelFileStoreError: Error {
    case documentsDirectoryUnavailable
}
