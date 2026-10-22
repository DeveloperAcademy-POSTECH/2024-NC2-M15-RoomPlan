//
//  StoryAlignmentGuide.swift
//  MyRaum
//
//  Created by Yune Cho on 10/22/26.
//

import SwiftUI

//카드 위의 요소를 옮길 때 맞춰지는 기준선
//인스타그램 스토리처럼 요소가 카드의 가운데나 가장자리 여백에 가까워지면 기준선에 붙고 선이 표시됨
enum StoryAlignmentGuide: Hashable {
    case vertical(x: CGFloat)
    case horizontal(y: CGFloat)
}

enum StoryAlignmentSnapper {
    //기준선에 붙기 시작하는 거리(포인트)
    static let threshold: CGFloat = 8

    //카드 가장자리에서 여백 기준선까지의 거리(기준 너비 360 기준)
    static let margin: CGFloat = 20

    //요소의 중심 위치를 가장 가까운 기준선에 맞추고, 맞춰진 기준선을 함께 돌려줌
    static func snap(center: CGPoint, elementSize: CGSize, canvasSize: CGSize, unit: CGFloat) -> (center: CGPoint, guides: Set<StoryAlignmentGuide>) {
        var guides: Set<StoryAlignmentGuide> = []

        let x = snapAxis(center.x, half: elementSize.width / 2, length: canvasSize.width, margin: margin * unit)
        if let line = x.line {
            guides.insert(.vertical(x: line))
        }

        let y = snapAxis(center.y, half: elementSize.height / 2, length: canvasSize.height, margin: margin * unit)
        if let line = y.line {
            guides.insert(.horizontal(y: line))
        }

        return (CGPoint(x: x.value, y: y.value), guides)
    }

    //한 축에서 가운데, 앞쪽 여백, 뒤쪽 여백 기준선 중 가장 가까운 곳에 맞춤
    private static func snapAxis(_ value: CGFloat, half: CGFloat, length: CGFloat, margin: CGFloat) -> (value: CGFloat, line: CGFloat?) {
        //(기준선 위치, 기준선에 맞췄을 때의 요소 중심 위치)
        var candidates: [(line: CGFloat, center: CGFloat)] = [(length / 2, length / 2)]

        //요소가 여백 안쪽에 들어갈 수 있을 때만 가장자리 기준선을 사용
        if half * 2 < length - margin * 2 {
            candidates.append((margin, margin + half))
            candidates.append((length - margin, length - margin - half))
        }

        let nearest = candidates
            .filter { abs(value - $0.center) <= threshold }
            .min { abs(value - $0.center) < abs(value - $1.center) }

        guard let nearest else { return (value, nil) }
        return (nearest.center, nearest.line)
    }
}

//맞춰진 기준선을 카드 위에 그리는 뷰
struct StoryAlignmentGuideOverlay: View {
    let guides: Set<StoryAlignmentGuide>
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            ForEach(Array(guides), id: \.self) { guide in
                switch guide {
                case .vertical(let x):
                    guideLine
                        .frame(width: 1, height: canvasSize.height)
                        .position(x: x, y: canvasSize.height / 2)
                case .horizontal(let y):
                    guideLine
                        .frame(width: canvasSize.width, height: 1)
                        .position(x: canvasSize.width / 2, y: y)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }

    //흰색 모델이나 밝은 사진 위에서도 잘 보이도록 파란색 선을 사용
    private var guideLine: some View {
        Rectangle()
            .fill(Color(red: 0.2, green: 0.6, blue: 1.0))
    }
}
