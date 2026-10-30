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
//가구 배치 편집 중에는 가구 탭: 선택, 가구 위에서 드래그: 이동, 두 손가락 회전: 선택된 가구 회전
struct RoomSceneView: UIViewRepresentable {
    let roomScene: RoomScene
    var snapshotter: RoomSceneSnapshotter? = nil
    var furnitureEditor: FurnitureEditor? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = roomScene.scene
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.pointOfView = roomScene.cameraNode
        //기본 카메라 컨트롤은 두 손가락 회전으로 카메라가 기울고, 가구 편집 제스처와 우선순위를 정하기 어려우므로
        //카메라 제스처를 Coordinator에서 직접 처리함
        view.allowsCameraControl = false

        snapshotter?.view = view
        context.coordinator.attach(to: view, roomScene: roomScene, editor: furnitureEditor)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {

    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.stopInertia()
    }
}

//사용자가 맞춘 각도 그대로 3D 모델을 이미지로 만들기 위한 클래스
final class RoomSceneSnapshotter {
    fileprivate weak var view: SCNView?

    func snapshot() -> UIImage? {
        //방금 바꾼 노드(가구 하이라이트 제거 등)가 반영된 화면을 찍도록 먼저 커밋
        SCNTransaction.flush()
        return view?.snapshot()
    }

    //사용자가 돌려놓은 현재 카메라 위치
    func cameraPose() -> CameraPose? {
        view?.pointOfView.map(CameraPose.init(node:))
    }
}

// MARK: - Camera Orbit
//중심점을 기준으로 수평 각도(yaw), 높낮이(pitch), 거리로 정하는 카메라 위치
//카메라의 위쪽을 항상 y축에 맞춰서 공간이 옆으로 기울어 보이지 않게 함
private struct RoomCameraOrbit {
    var target: SIMD3<Float>
    var yaw: Float
    var pitch: Float
    var distance: Float

    static let pitchRange: ClosedRange<Float> = (-10 * .pi / 180)...(88 * .pi / 180)

    //지금 카메라가 바라보는 방향은 그대로 두고 회전 중심을 정함
    //저장된 각도로 연 카드도 첫 회전에서 화면이 튀지 않도록 바라보는 방향 위에서 공간 중심과 가장 가까운 점을 중심으로 사용
    init(cameraNode: SCNNode, center: SIMD3<Float>) {
        let position = cameraNode.simdWorldPosition
        let forward = simd_normalize(cameraNode.simdWorldFront)
        let along = simd_dot(center - position, forward)
        distance = along > 0.1 ? along : max(simd_length(center - position), 0.5)
        target = position + forward * distance

        let offset = position - target
        yaw = atan2(offset.x, offset.z)
        pitch = asin(min(max(offset.y / distance, -1), 1))
    }

    func apply(to node: SCNNode) {
        let direction = SIMD3<Float>(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
        node.simdPosition = target + direction * distance
        node.simdLook(at: target, up: [0, 1, 0], localFront: SCNNode.simdLocalFront)
    }
}

// MARK: - Gestures
extension RoomSceneView {
    //카메라 제스처와 가구 편집 제스처를 함께 처리하는 클래스
    //- 한 손가락 드래그: 가구 위에서 시작하면 가구 이동, 빈 곳에서 시작하면 공간 회전
    //- 두 손가락 이동, 핀치: 카메라 이동, 확대/축소 (가구가 선택되어 있으면 막음)
    //- 두 손가락 회전: 선택된 가구 회전 (카메라는 기울이지 않음)
    //- 가구를 옮기거나 돌리는 동안에는 카메라를 고정
    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var view: SCNView?
        private var editor: FurnitureEditor?
        private var cameraNode: SCNNode?
        private var center: SIMD3<Float> = .zero
        private var radius: Float = 1
        private var orbit: RoomCameraOrbit?

        private let tapGesture = UITapGestureRecognizer()
        private let panGesture = UIPanGestureRecognizer()
        private let twoFingerPanGesture = UIPanGestureRecognizer()
        private let pinchGesture = UIPinchGestureRecognizer()
        private let rotationGesture = UIRotationGestureRecognizer()

        //드래그 제스처는 조금 움직인 뒤에 시작되므로 손가락이 처음 닿은 위치를 기억해둠
        private var touchStart: CGPoint?
        private var touchStartTime: TimeInterval = 0
        //가구 회전이 끝난 시각 - 회전하던 손가락 중 남은 손가락으로 공간이 돌아가지 않게 할 때 사용
        private var furnitureRotationEndTime: TimeInterval = 0
        //가구 위에서 시작한 드래그면 그 가구의 ID - nil이면 공간 회전
        private var draggingID: UUID?
        private var isRotatingFurniture: Bool = false
        private var pinchStartDistance: Float?

        //손가락을 뗀 뒤에도 잠깐 이어지는 공간 회전 (yaw, pitch의 초당 변화량)
        private var displayLink: CADisplayLink?
        private var inertiaVelocity: SIMD2<Float> = .zero

        func attach(to view: SCNView, roomScene: RoomScene, editor: FurnitureEditor?) {
            self.view = view
            self.editor = editor
            cameraNode = roomScene.cameraNode
            center = SIMD3<Float>(roomScene.target)
            radius = roomScene.radius

            tapGesture.addTarget(self, action: #selector(handleTap(_:)))
            panGesture.addTarget(self, action: #selector(handlePan(_:)))
            panGesture.maximumNumberOfTouches = 1
            twoFingerPanGesture.addTarget(self, action: #selector(handleTwoFingerPan(_:)))
            twoFingerPanGesture.minimumNumberOfTouches = 2
            twoFingerPanGesture.maximumNumberOfTouches = 2
            pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))
            rotationGesture.addTarget(self, action: #selector(handleRotation(_:)))

            for gesture in [tapGesture, panGesture, twoFingerPanGesture, pinchGesture, rotationGesture] as [UIGestureRecognizer] {
                gesture.delegate = self
                view.addGestureRecognizer(gesture)
            }
        }

        // MARK: Gesture Delegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            //화면을 다시 만지면 이어지던 회전을 멈춤
            stopInertia()
            if gestureRecognizer === panGesture {
                //드래그가 시작된 뒤에 닿은 손가락은 받지 않음
                //시작하기 전에 두 손가락이 닿으면 한 손가락 드래그로 인식되지 않으므로 공간이 돌아가지 않음
                guard panGesture.state == .possible else { return false }
                if panGesture.numberOfTouches == 0 {
                    touchStart = touch.location(in: view)
                    touchStartTime = touch.timestamp
                }
            }
            return true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            switch gestureRecognizer {
            case tapGesture:
                return isEditing
            case panGesture:
                //두 손가락이 닿아 있거나, 가구를 돌리던 손가락 중 하나를 먼저 뗀 경우에는 한 손가락 드래그로 보지 않음
                guard panGesture.numberOfTouches <= 1,
                      !isRotatingFurniture,
                      touchStartTime > furnitureRotationEndTime else { return false }
                //편집 중에 가구 위에서 시작한 드래그는 가구를 옮기고, 그 외에는 공간을 돌림
                draggingID = isEditing ? touchStart.flatMap(furnitureID(near:)) : nil
                return true
            case rotationGesture:
                return isFurnitureSelected
            case twoFingerPanGesture, pinchGesture:
                //가구가 선택되어 있으면 두 손가락 제스처는 가구 회전에만 사용
                return !isFurnitureSelected && draggingID == nil && !isRotatingFurniture
            default:
                return true
            }
        }

        //카메라 이동과 확대/축소는 함께 할 수 있음
        //두 손가락을 대는 사이에 첫 손가락의 드래그가 먼저 시작되어도 가구 회전이 막히지 않도록 드래그와 회전도 함께 인식함
        //(가구 회전이 시작되면 드래그를 취소함)
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            let cameraGestures: [UIGestureRecognizer] = [twoFingerPanGesture, pinchGesture]
            let rotateGestures: [UIGestureRecognizer] = [panGesture, rotationGesture]
            return (cameraGestures.contains(gestureRecognizer) && cameraGestures.contains(otherGestureRecognizer))
                || (rotateGestures.contains(gestureRecognizer) && rotateGestures.contains(otherGestureRecognizer))
        }

        // MARK: Gesture Handlers
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let editor else { return }
            editor.select(furnitureID(at: gesture.location(in: view)))
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            if draggingID != nil {
                moveFurniture(gesture)
            } else {
                orbitCamera(gesture)
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let editor else { return }
            switch gesture.state {
            case .began:
                //먼저 시작된 한 손가락 드래그는 여기서 끝내고 가구 회전만 남김
                if panGesture.state == .began || panGesture.state == .changed {
                    editor.endMove()
                    draggingID = nil
                    stopInertia()
                    //isEnabled를 끄면 진행 중인 드래그가 취소되고, 지금 닿아 있는 손가락은 다시 받지 않음
                    panGesture.isEnabled = false
                    panGesture.isEnabled = true
                }
                isRotatingFurniture = editor.beginRotation()
            case .changed:
                //화면에서 시계 방향이 양수이므로 위에서 내려다본 y축 회전 방향에 맞게 부호를 바꿈
                editor.rotate(by: -Float(gesture.rotation))
            case .ended, .cancelled, .failed:
                editor.endRotation()
                isRotatingFurniture = false
                furnitureRotationEndTime = ProcessInfo.processInfo.systemUptime
            default:
                break
            }
        }

        //두 손가락으로 회전 중심을 화면과 나란한 방향으로 옮김
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .changed, let view, let cameraNode, var orbit = currentOrbit() else { return }
            let translation = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)

            //중심점 거리에서 화면 1포인트가 차지하는 월드 길이 (시야각은 가로 기준)
            let fieldOfView = Float(cameraNode.camera?.fieldOfView ?? 30) * .pi / 180
            let unit = 2 * orbit.distance * tan(fieldOfView / 2) / Float(max(view.bounds.width, 1))
            let move = -cameraNode.simdWorldRight * Float(translation.x) * unit + cameraNode.simdWorldUp * Float(translation.y) * unit
            //공간 밖으로 너무 멀리 나가지 않도록 제한
            orbit.target = simd_clamp(orbit.target + move, center - radius, center + radius)
            update(orbit)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                pinchStartDistance = currentOrbit()?.distance
            case .changed:
                guard let start = pinchStartDistance, var orbit = currentOrbit() else { return }
                orbit.distance = min(max(start / Float(max(gesture.scale, 0.01)), radius * 0.5), radius * 8)
                update(orbit)
            default:
                pinchStartDistance = nil
            }
        }

        @objc func stepInertia(_ link: CADisplayLink) {
            guard var orbit = currentOrbit() else {
                stopInertia()
                return
            }
            let delta = Float(min(link.duration, 1.0 / 30))
            orbit.yaw += inertiaVelocity.x * delta
            orbit.pitch = clampedPitch(orbit.pitch + inertiaVelocity.y * delta)
            update(orbit)

            //빠르게 줄어들어서 손을 뗀 뒤 너무 오래 돌지 않게 함
            inertiaVelocity *= exp(-6 * delta)
            if simd_length(inertiaVelocity) < 0.05 {
                stopInertia()
            }
        }

        func stopInertia() {
            displayLink?.invalidate()
            displayLink = nil
            inertiaVelocity = .zero
        }
    }
}

private extension RoomSceneView.Coordinator {
    var isEditing: Bool {
        editor?.isEditing == true
    }

    var isFurnitureSelected: Bool {
        isEditing && editor?.selectedID != nil
    }

    //화면을 가로지르면 반 바퀴 돌아감
    var orbitSensitivity: Float {
        .pi / Float(max(view?.bounds.width ?? 1, 1))
    }

    func clampedPitch(_ pitch: Float) -> Float {
        min(max(pitch, RoomCameraOrbit.pitchRange.lowerBound), RoomCameraOrbit.pitchRange.upperBound)
    }

    //처음 카메라를 움직일 때 지금 카메라 위치로 회전 중심을 정하고, 이후에는 같은 중심을 계속 사용
    func currentOrbit() -> RoomCameraOrbit? {
        if let orbit { return orbit }
        guard let cameraNode else { return nil }
        let orbit = RoomCameraOrbit(cameraNode: cameraNode, center: center)
        self.orbit = orbit
        return orbit
    }

    func update(_ orbit: RoomCameraOrbit) {
        self.orbit = orbit
        if let cameraNode {
            orbit.apply(to: cameraNode)
        }
    }

    //손가락을 따라 공간이 돌아가도록 카메라를 반대 방향으로 돌림
    func orbitCamera(_ gesture: UIPanGestureRecognizer) {
        //가구를 돌리는 동안에는 공간을 고정
        guard let view, !isRotatingFurniture else { return }
        switch gesture.state {
        case .changed:
            guard var orbit = currentOrbit() else { return }
            let translation = gesture.translation(in: view)
            gesture.setTranslation(.zero, in: view)
            orbit.yaw -= Float(translation.x) * orbitSensitivity
            orbit.pitch = clampedPitch(orbit.pitch + Float(translation.y) * orbitSensitivity)
            update(orbit)
        case .ended:
            let velocity = gesture.velocity(in: view)
            startInertia(SIMD2(-Float(velocity.x), Float(velocity.y)) * orbitSensitivity)
        default:
            break
        }
    }

    func startInertia(_ velocity: SIMD2<Float>) {
        stopInertia()
        //천천히 손을 떼면 바로 멈춤
        guard simd_length(velocity) > 0.8 else { return }
        inertiaVelocity = velocity
        let link = CADisplayLink(target: self, selector: #selector(stepInertia(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func moveFurniture(_ gesture: UIPanGestureRecognizer) {
        //가구 회전이 시작된 뒤에는 드래그로 가구를 옮기지 않음
        guard let editor, !isRotatingFurniture else { return }
        switch gesture.state {
        case .began:
            guard let id = draggingID,
                  let start = touchStart.flatMap(floorPoint(at:)) else { return }
            editor.beginMove(id, from: start)
            if let point = floorPoint(at: gesture.location(in: view)) {
                editor.move(to: point)
            }
        case .changed:
            if let point = floorPoint(at: gesture.location(in: view)) {
                editor.move(to: point)
            }
        case .ended, .cancelled, .failed:
            editor.endMove()
            draggingID = nil
        default:
            break
        }
    }

    //드래그를 시작한 위치 주변의 가구 - 가구 가장자리를 살짝 벗어나서 시작해도 가구를 옮길 수 있게 함
    //손가락 바로 아래의 가구를 먼저 찾고, 없으면 주변에서 선택된 가구, 그다음 가까운 가구 순서로 찾음
    func furnitureID(near location: CGPoint) -> UUID? {
        if let id = furnitureID(at: location) {
            return id
        }
        let radius: CGFloat = 16
        let samples = (0..<8).map { index -> CGPoint in
            let angle = CGFloat(index) * .pi / 4
            return CGPoint(x: location.x + cos(angle) * radius, y: location.y + sin(angle) * radius)
        }
        let ids = samples.compactMap(furnitureID(at:))
        if let selectedID = editor?.selectedID, ids.contains(selectedID) {
            return selectedID
        }
        return ids.first
    }

    //화면의 위치에서 가장 가까운 가구 - 벽과 바닥은 무시하고 뒤에 있는 가구를 찾음
    func furnitureID(at location: CGPoint) -> UUID? {
        guard let view, let layer = editor?.layer else { return nil }
        let results = view.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true
        ])
        for result in results {
            if let id = layer.furnitureID(containing: result.node) {
                return id
            }
        }
        return nil
    }

    //화면의 위치를 바닥 높이의 수평면에 투영한 점
    func floorPoint(at location: CGPoint) -> SIMD3<Float>? {
        guard let view, let floorY = editor?.layer.floorY else { return nil }
        let near = SIMD3<Float>(view.unprojectPoint(SCNVector3(Float(location.x), Float(location.y), 0)))
        let far = SIMD3<Float>(view.unprojectPoint(SCNVector3(Float(location.x), Float(location.y), 1)))
        let direction = far - near
        //카메라가 바닥과 거의 평행하면 투영한 점이 너무 멀어지므로 무시
        guard abs(direction.y) > 1e-4 else { return nil }
        let distance = (floorY - near.y) / direction.y
        guard distance > 0 else { return nil }
        return near + direction * distance
    }
}
