//
//  RoomSceneView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI
import SceneKit

//3D 공간을 손가락으로 돌려볼 수 있는 뷰
//한 손가락: 회전, 두 손가락: 이동, 핀치: 확대/축소
struct RoomSceneView: UIViewRepresentable {
    let roomScene: RoomScene
    var snapshotter: RoomSceneSnapshotter? = nil

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = roomScene.scene
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.pointOfView = roomScene.cameraNode
        view.allowsCameraControl = true

        let controller = view.defaultCameraController
        controller.interactionMode = .orbitTurntable
        controller.target = roomScene.target
        controller.inertiaEnabled = true
        controller.minimumVerticalAngle = -10
        controller.maximumVerticalAngle = 89

        snapshotter?.view = view
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {

    }
}

//사용자가 맞춘 각도 그대로 3D 모델을 이미지로 만들기 위한 클래스
final class RoomSceneSnapshotter {
    fileprivate weak var view: SCNView?

    func snapshot() -> UIImage? {
        view?.snapshot()
    }
}
