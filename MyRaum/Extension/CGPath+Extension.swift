//
//  CGPath+Extension.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import CoreGraphics
import simd

extension CGPath {
    //곡선을 짧은 직선으로 나눠서 하위 경로별 다각형으로 변환
    func flattenedPolygons(segmentsPerCurve: Int = 8) -> [[SIMD2<Float>]] {
        var polygons: [[SIMD2<Float>]] = []
        var current: [SIMD2<Float>] = []
        var last = CGPoint.zero

        func append(_ point: CGPoint) {
            let value = SIMD2(Float(point.x), Float(point.y))
            if let previous = current.last, simd_distance(previous, value) < 0.0001 { return }
            current.append(value)
        }

        func finish() {
            if let first = current.first, let end = current.last, current.count > 1, simd_distance(first, end) < 0.0001 {
                current.removeLast()
            }
            if current.count >= 3 {
                polygons.append(current)
            }
            current = []
        }

        applyWithBlock { pointer in
            let element = pointer.pointee
            let points = element.points
            switch element.type {
            case .moveToPoint:
                finish()
                append(points[0])
                last = points[0]
            case .addLineToPoint:
                append(points[0])
                last = points[0]
            case .addQuadCurveToPoint:
                for step in 1...segmentsPerCurve {
                    let t = CGFloat(step) / CGFloat(segmentsPerCurve)
                    let u = 1 - t
                    append(CGPoint(
                        x: u * u * last.x + 2 * u * t * points[0].x + t * t * points[1].x,
                        y: u * u * last.y + 2 * u * t * points[0].y + t * t * points[1].y
                    ))
                }
                last = points[1]
            case .addCurveToPoint:
                for step in 1...segmentsPerCurve {
                    let t = CGFloat(step) / CGFloat(segmentsPerCurve)
                    let u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    append(CGPoint(
                        x: a * last.x + b * points[0].x + c * points[1].x + d * points[2].x,
                        y: a * last.y + b * points[0].y + c * points[1].y + d * points[2].y
                    ))
                }
                last = points[2]
            case .closeSubpath:
                finish()
            @unknown default:
                break
            }
        }
        finish()

        return polygons
    }
}
