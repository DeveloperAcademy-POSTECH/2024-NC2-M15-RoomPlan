//
//  StoryDraft.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import UIKit
import CoreLocation
import simd

//공간 카드를 꾸미는 동안 사용자가 추가한 요소들을 담아두는 임시 데이터
//저장하기 전까지는 SwiftData에 들어가지 않음
@Observable
final class StoryDraft {
    private(set) var elements: [StoryElement] = []
    private(set) var background: UIImage?
    private(set) var backgroundPreset: Int = 0
    //가구 배치 편집 결과 - 저장할 때 공유용 USDZ 파일에도 반영
    private(set) var arrangement = FurnitureArrangement()
    //저장된 카드를 수정할 때 배경을 바꾸지 않았으면 다시 압축하지 않도록 구분
    @ObservationIgnored private var isBackgroundChanged: Bool = false

    init() {}

    //저장된 공간 카드를 다시 꾸밀 때 사용
    init(record: SpaceRecord) {
        elements = record.elements
        background = record.backgroundImage
        backgroundPreset = record.backgroundPreset
        arrangement = record.arrangement ?? FurnitureArrangement()
    }

    //보관함에서 보여줄 이름 (장소 요소의 텍스트)
    var title: String {
        element(of: .location)?.text ?? element(of: .text)?.text ?? ""
    }

    func element(of kind: StoryElement.Kind) -> StoryElement? {
        elements.first { $0.kind == kind }
    }

    func element(id: UUID) -> StoryElement? {
        elements.first { $0.id == id }
    }

    @discardableResult
    func add(_ kind: StoryElement.Kind, text: String = "") -> StoryElement {
        var position = Self.defaultPosition(for: kind)
        //텍스트를 여러 개 추가하면 겹치지 않도록 조금씩 아래에 배치
        if kind == .text {
            let count = elements.filter { $0.kind == .text }.count
            position.y += CGFloat(count % 5) * 0.07
        }
        let element = StoryElement(kind: kind, text: text, position: position)
        elements.append(element)
        return element
    }

    func remove(id: UUID) {
        elements.removeAll { $0.id == id }
    }

    func update(id: UUID, _ change: (inout StoryElement) -> Void) {
        guard let index = elements.firstIndex(where: { $0.id == id }) else { return }
        change(&elements[index])
    }

    //배경을 사진으로 설정
    func setBackground(_ image: UIImage) {
        //큰 사진은 저장 용량을 줄이기 위해 크기를 줄여서 보관
        background = Self.downscaled(image)
        isBackgroundChanged = true
    }

    //배경을 그라데이션으로 설정 (사진은 지움)
    func setBackgroundPreset(_ index: Int) {
        background = nil
        backgroundPreset = index
        isBackgroundChanged = true
    }

    //가구를 옮기거나 돌린 뒤의 최종 위치를 저장 - 원래 위치로 되돌리면 nil
    func setFurnitureTransform(_ transform: simd_float4x4?, for id: UUID) {
        arrangement.setTransform(transform, for: id)
    }

    //가구 목록에서 가구를 추가
    func addFurniture(_ addition: FurnitureArrangement.Addition) {
        arrangement.add(addition)
    }

    //추가한 가구나 스캔 가구를 지움
    func removeFurniture(id: UUID) {
        arrangement.remove(id)
    }

    //가구 배치를 바꿨으면 바뀐 배치로 USDZ 파일을 새로 만들어서 저장
    @MainActor
    func makeRecord(room: ScannedRoom, thumbnail: UIImage, cameraPose: CameraPose?, coordinate: CLLocationCoordinate2D?) async -> SpaceRecord? {
        let arrangement = self.arrangement
        guard let modelURL = try? await room.modelURL(applying: arrangement),
              let modelFile = try? Data(contentsOf: modelURL),
              let thumbnailData = thumbnail.pngData() else {
            return nil
        }

        return SpaceRecord(
            createdAt: .now,
            title: title,
            modelFile: modelFile,
            roomData: room.roomData,
            thumbnail: thumbnailData,
            background: background?.jpegData(compressionQuality: 0.8),
            backgroundPreset: backgroundPreset,
            elements: elements,
            furniture: room.furniture(applying: arrangement),
            coordinate: coordinate,
            cameraPose: cameraPose,
            arrangement: arrangement.isEmpty ? nil : arrangement
        )
    }

    //수정한 내용을 저장된 공간 카드에 반영 - 생성 날짜, 위치는 그대로 유지
    @MainActor
    func apply(to record: SpaceRecord, room: ScannedRoom, thumbnail: UIImage, cameraPose: CameraPose?) async -> Bool {
        guard let thumbnailData = thumbnail.pngData() else { return false }
        
        //RoomPlan 원본 데이터로 USDZ 파일을 새로 만든 경우 저장된 파일도 교체
        //가구 배치를 바꿨으면 바뀐 배치로 파일을 다시 만듦 (USDZ 파일로 연 경우에는 배치를 편집할 수 없으므로 파일, 배치, 가구 목록 모두 그대로 유지)
        if room.layout != nil {
            let arrangement = self.arrangement
            guard let modelURL = try? await room.modelURL(applying: arrangement),
                  let modelFile = try? Data(contentsOf: modelURL) else {
                return false
            }
            record.modelFile = modelFile
            record.arrangement = arrangement.isEmpty ? nil : arrangement
            //가구를 추가하거나 지웠으면 보관함과 3D 보기의 가구 목록에도 반영
            record.furnitureKeys = room.furniture(applying: arrangement).map(\.rawValue)
        }

        record.title = title
        record.thumbnail = thumbnailData
        record.elements = elements
        record.cameraPose = cameraPose
        if isBackgroundChanged {
            record.background = background?.jpegData(compressionQuality: 0.8)
            record.backgroundPreset = backgroundPreset
        }
        return true
    }
}

private extension StoryDraft {
    static func defaultPosition(for kind: StoryElement.Kind) -> CGPoint {
        switch kind {
        case .text: CGPoint(x: 0.5, y: 0.45)
        case .location: CGPoint(x: 0.5, y: 0.1)
        case .date: CGPoint(x: 0.75, y: 0.93)
        case .furniture: CGPoint(x: 0.5, y: 0.82)
        }
    }

    static func downscaled(_ image: UIImage) -> UIImage {
        let maxLength: CGFloat = 1600
        let longest = max(image.size.width, image.size.height)
        guard longest > maxLength else { return image }
        let ratio = maxLength / longest
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        return image.resize(to: size) ?? image
    }
}
