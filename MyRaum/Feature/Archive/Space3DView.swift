//
//  Space3DView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import RealityKit

//저장된 USDZ 모델을 회전·확대할 수 있게 보여주는 뷰
//최소 배포 타겟이 18.0이므로 버전 분기 없이 RealityView를 사용한다 (D-01)
struct Space3DView: View {
    let modelURL: URL
    
    //진입할 때마다 초기 각도로 시작한다 (회전 상태를 카드별로 유지하지 않음)
    @State private var rotation: Double = 0
    @State private var dragStartRotation: Double = 0
    @State private var scale: Double = 1
    @State private var pinchStartScale: Double = 1
    @State private var didFailToLoad: Bool = false
    
    //핀치로 조절할 수 있는 배율 범위
    private let scaleRange: ClosedRange<Double> = 0.5...3.0
    
    var body: some View {
        ZStack {
            if didFailToLoad {
                //모델 파일을 열지 못해도 카드 자체는 계속 보여준다
                Image(systemName: "cube.transparent")
                    .resizable()
                    .scaledToFit()
                    .padding(60)
                    .foregroundStyle(Color.white.opacity(0.5))
            } else {
                modelView
            }
        }
    }
}

private extension Space3DView {
    var modelView: some View {
        RealityView { content in
            guard let model = try? await ModelEntity(contentsOf: modelURL) else {
                didFailToLoad = true
                return
            }
            
            //모델을 원점 기준으로 맞추고 카드 안에 담기도록 크기를 줄인다
            let bounds = model.visualBounds(relativeTo: nil)
            model.position = -bounds.center
            
            let container = Entity()
            container.addChild(model)
            container.scale = SIMD3(repeating: Float(Space3DView.fittingScale(extents: bounds.extents)))
            container.name = Space3DView.containerName
            content.add(container)
            
            //비 AR 렌더이므로 모델을 비추는 카메라를 직접 넣는다
            let camera = PerspectiveCamera()
            camera.position = [0, 0.35, 1.4]
            camera.look(at: .zero, from: camera.position, relativeTo: nil)
            content.add(camera)
        } update: { content in
            guard let container = content.entities.first(where: { $0.name == Space3DView.containerName }) else { return }
            
            container.transform.rotation = simd_quatf(angle: Float(rotation), axis: [0, 1, 0])
        }
        .scaleEffect(scale)
        .gesture(rotateGesture)
        .simultaneousGesture(zoomGesture)
    }
    
    //좌우로 끌어 Y축 회전
    var rotateGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                rotation = dragStartRotation + Double(value.translation.width) * 0.01
            }
            .onEnded { _ in
                dragStartRotation = rotation
            }
    }
    
    //핀치로 확대·축소
    var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(pinchStartScale * value.magnification, scaleRange.lowerBound), scaleRange.upperBound)
            }
            .onEnded { _ in
                pinchStartScale = scale
            }
    }
}

extension Space3DView {
    static let containerName = "spaceModelContainer"
    
    //모델의 가장 긴 변이 기준 크기에 맞도록 배율을 계산하는 함수
    static func fittingScale(extents: SIMD3<Float>, targetExtent: Float = 1.0) -> Double {
        let longestEdge = max(extents.x, max(extents.y, extents.z))
        guard longestEdge > 0 else { return 1 }
        return Double(targetExtent / longestEdge)
    }
}
