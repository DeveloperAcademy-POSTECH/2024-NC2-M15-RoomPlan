//
//  SpaceGrouping.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//보관함에 한 칸으로 보이는 단위
//단일 방이거나, 여러 방을 묶은 구조다 (8.1)
struct SpaceGroup: Identifiable {
    let id: UUID
    //구조에 속하면 구조 식별자, 아니면 nil
    let structureID: UUID?
    //구조 안에서 순서대로 정렬된 방들
    let rooms: [SpaceData]
    
    //목록에 보여줄 대표 방
    var representative: SpaceData? { rooms.first }
    var roomCount: Int { rooms.count }
    var isStructure: Bool { structureID != nil && rooms.count > 1 }
}

//저장된 공간을 구조 단위로 묶어 주는 역할
enum SpaceGrouping {
    //구조에 속한 방들은 하나로 묶고, 단일 방은 그대로 둔다
    //입력 순서(최신순)를 유지한다
    static func group(_ spaces: [SpaceData]) -> [SpaceGroup] {
        var groups: [SpaceGroup] = []
        var handledStructures = Set<UUID>()
        
        for space in spaces {
            guard let structureID = space.structureID else {
                groups.append(SpaceGroup(id: space.id, structureID: nil, rooms: [space]))
                continue
            }
            
            guard handledStructures.contains(structureID) == false else { continue }
            handledStructures.insert(structureID)
            
            //구조 안에서는 스캔한 순서대로 보여준다
            let rooms = spaces
                .filter { $0.structureID == structureID }
                .sorted { ($0.structureOrder ?? 0) < ($1.structureOrder ?? 0) }
            
            groups.append(SpaceGroup(id: structureID, structureID: structureID, rooms: rooms))
        }
        
        return groups
    }
}
