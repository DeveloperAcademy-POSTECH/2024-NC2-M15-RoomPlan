//
//  RoomLayout.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import simd
import RoomPlan

//3D 모델을 그리는 데 필요한 정보만 CapturedRoom에서 뽑아낸 데이터
//RoomPlan 타입과 분리해두어서 모델을 만드는 코드가 CapturedRoom 없이도 동작함
struct RoomLayout {
    struct Wall {
        var id: UUID
        //벽의 중심 기준 - x축: 벽의 가로 방향, y축: 위쪽, z축: 벽의 법선 방향
        var transform: simd_float4x4
        //(가로, 높이, 0)
        var dimensions: SIMD3<Float>
    }

    struct Opening {
        enum Kind {
            case door(isOpen: Bool)
            case window
            case opening
        }

        var kind: Kind
        var transform: simd_float4x4
        var dimensions: SIMD3<Float>
        var parentID: UUID?
    }

    struct Floor {
        var transform: simd_float4x4
        var dimensions: SIMD3<Float>
        //다각형 바닥의 꼭짓점 (바닥의 로컬 좌표)
        var corners: [SIMD3<Float>]
    }

    struct Object {
        var id: UUID
        var category: FurnitureCategory
        //가구의 중심 기준 - y축: 위쪽
        var transform: simd_float4x4
        //(가로, 높이, 깊이)
        var dimensions: SIMD3<Float>
        var parentID: UUID?
        var attributes: FurnitureAttributes
    }

    var walls: [Wall]
    var openings: [Opening]
    var floors: [Floor]
    var objects: [Object]
}

//RoomPlan이 인식한 가구의 형태 정보 (iOS 17+)
struct FurnitureAttributes {
    var chairType: ChairType?
    var chairLeg: ChairLegType?
    var chairArm: ChairArmType?
    var chairBack: ChairBackType?
    var sofaType: SofaType?
    var tableType: TableType?
    var tableShape: TableShapeType?
    var storageType: StorageType?

    init(
        chairType: ChairType? = nil,
        chairLeg: ChairLegType? = nil,
        chairArm: ChairArmType? = nil,
        chairBack: ChairBackType? = nil,
        sofaType: SofaType? = nil,
        tableType: TableType? = nil,
        tableShape: TableShapeType? = nil,
        storageType: StorageType? = nil
    ) {
        self.chairType = chairType
        self.chairLeg = chairLeg
        self.chairArm = chairArm
        self.chairBack = chairBack
        self.sofaType = sofaType
        self.tableType = tableType
        self.tableShape = tableShape
        self.storageType = storageType
    }

    init(_ attributes: [any CapturedRoomAttribute]) {
        for attribute in attributes {
            switch attribute {
            case let value as ChairType: chairType = value
            case let value as ChairLegType: chairLeg = value
            case let value as ChairArmType: chairArm = value
            case let value as ChairBackType: chairBack = value
            case let value as SofaType: sofaType = value
            case let value as TableType: tableType = value
            case let value as TableShapeType: tableShape = value
            case let value as StorageType: storageType = value
            default: break
            }
        }
    }
}

extension RoomLayout {
    init(_ room: CapturedRoom) {
        walls = room.walls.map {
            Wall(id: $0.identifier, transform: $0.transform, dimensions: $0.dimensions)
        }

        let doors = room.doors.compactMap { surface -> Opening? in
            guard case .door(let isOpen) = surface.category else { return nil }
            return Opening(kind: .door(isOpen: isOpen), transform: surface.transform, dimensions: surface.dimensions, parentID: surface.parentIdentifier)
        }
        let windows = room.windows.map {
            Opening(kind: .window, transform: $0.transform, dimensions: $0.dimensions, parentID: $0.parentIdentifier)
        }
        let openings = room.openings.map {
            Opening(kind: .opening, transform: $0.transform, dimensions: $0.dimensions, parentID: $0.parentIdentifier)
        }
        self.openings = doors + windows + openings

        floors = room.floors.map {
            Floor(transform: $0.transform, dimensions: $0.dimensions, corners: $0.polygonCorners)
        }

        objects = room.objects.compactMap { object in
            guard let category = FurnitureCategory(object.category) else { return nil }
            return Object(
                id: object.identifier,
                category: category,
                transform: object.transform,
                dimensions: object.dimensions,
                parentID: object.parentIdentifier,
                attributes: FurnitureAttributes(object.attributes)
            )
        }
    }
}
