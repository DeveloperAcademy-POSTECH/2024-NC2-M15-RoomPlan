//
//  StoryDraft.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import UIKit
import CoreLocation

//공간 카드를 꾸미는 동안 사용자가 추가한 요소들을 담아두는 임시 데이터
//저장하기 전까지는 SwiftData에 들어가지 않음
@Observable
final class StoryDraft {
    private(set) var elements: [StoryElement] = []
    private(set) var background: UIImage?
    private(set) var backgroundPreset: Int = 0

    func element(of kind: StoryElement.Kind) -> StoryElement? {
        elements.first { $0.kind == kind }
    }

    func element(id: UUID) -> StoryElement? {
        elements.first { $0.id == id }
    }

    @discardableResult
    func add(_ kind: StoryElement.Kind, text: String = "") -> StoryElement {
        let element = StoryElement(kind: kind, text: text, position: Self.defaultPosition(for: kind))
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

    func setBackground(_ image: UIImage?) {
        //큰 사진은 저장 용량을 줄이기 위해 크기를 줄여서 보관
        background = image.flatMap(Self.downscaled)
    }

    //배경 사진을 지우고 다음 그라데이션으로 변경
    func nextBackgroundPreset() {
        background = nil
        backgroundPreset = (backgroundPreset + 1) % StoryBackgroundPreset.gradients.count
    }

    func makeRecord(room: ScannedRoom, thumbnail: UIImage, coordinate: CLLocationCoordinate2D?) -> SpaceRecord? {
        guard let modelFile = try? Data(contentsOf: room.modelURL),
              let thumbnailData = thumbnail.pngData() else {
            return nil
        }

        let title = element(of: .location)?.text ?? element(of: .text)?.text ?? ""

        return SpaceRecord(
            createdAt: .now,
            title: title,
            modelFile: modelFile,
            roomData: room.roomData,
            thumbnail: thumbnailData,
            background: background?.jpegData(compressionQuality: 0.8),
            backgroundPreset: backgroundPreset,
            elements: elements,
            furniture: room.furniture,
            coordinate: coordinate
        )
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
