//
//  StoryElement.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI

//공간 카드 위에 스토리처럼 추가하는 요소
struct StoryElement: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case text
        case location
        case date
        case furniture
    }

    var id: UUID = UUID()
    var kind: Kind
    var text: String
    //카드 크기에 대한 상대 위치 (0...1)
    var position: CGPoint
    var scale: CGFloat = 1
}

//공간 카드의 배경으로 선택할 수 있는 그라데이션
//저장된 카드는 index로 참조하므로 순서를 바꾸면 안 되고 뒤에 추가만 해야 함
enum StoryBackgroundPreset {
    static let gradients: [[Color]] = [
        [Color(red: 0.11, green: 0.11, blue: 0.12), Color(red: 0.27, green: 0.27, blue: 0.29)],
        [Color(red: 0.95, green: 0.60, blue: 0.29), Color(red: 0.95, green: 0.79, blue: 0.30)],
        [Color(red: 0.18, green: 0.50, blue: 0.93), Color(red: 0.34, green: 0.80, blue: 0.95)],
        [Color(red: 0.56, green: 0.18, blue: 0.89), Color(red: 0.29, green: 0.00, blue: 0.88)],
        [Color(red: 0.07, green: 0.60, blue: 0.56), Color(red: 0.22, green: 0.94, blue: 0.49)],
        [Color(red: 0.93, green: 0.45, blue: 0.53), Color(red: 0.98, green: 0.71, blue: 0.62)]
    ]

    static func gradient(at index: Int) -> LinearGradient {
        let colors = gradients.indices.contains(index) ? gradients[index] : gradients[0]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

//공간 카드의 비율과 기준 크기
//요소의 글자 크기 등은 기준 너비(360)를 기준으로 정의하고 실제 크기에 맞춰 비율로 조정
enum StoryLayout {
    static let referenceWidth: CGFloat = 360
    static let aspectRatio: CGFloat = 9 / 16

    static func size(fittingWidth width: CGFloat) -> CGSize {
        CGSize(width: width, height: width / aspectRatio)
    }

    static func size(fitting container: CGSize) -> CGSize {
        let width = min(container.width, container.height * aspectRatio)
        return size(fittingWidth: width)
    }
}
