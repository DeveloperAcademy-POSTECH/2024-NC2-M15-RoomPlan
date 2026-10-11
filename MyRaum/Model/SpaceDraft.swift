//
//  SpaceDraft.swift
//  MyRaum
//
//  Created by Yune Cho on 10/11/26.
//

import UIKit
import CoreLocation

//공간 카드를 만드는 동안 사용자가 추가한 요소들을 담아두는 임시 데이터
//저장하기 전까지는 SwiftData에 들어가지 않음
@Observable
final class SpaceDraft {
    var model: UIImage?
    var background: UIImage?
    var comment: String = ""
    var date: Date?
    var coordinate: CLLocationCoordinate2D?

    var dateString: String? {
        date?.cardDateString
    }

    //저장에 필요한 요소들이 모두 추가된 경우에만 SpaceData를 생성
    func makeSpaceData() -> SpaceData? {
        guard let modelData = model?.pngData(),
              let backgroundData = background?.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        return SpaceData(
            id: UUID(),
            date: (date ?? .now).cardDateString,
            comment: comment,
            model: modelData,
            background: backgroundData,
            latitude: coordinate?.latitude ?? 0,
            longitude: coordinate?.longitude ?? 0
        )
    }
}
