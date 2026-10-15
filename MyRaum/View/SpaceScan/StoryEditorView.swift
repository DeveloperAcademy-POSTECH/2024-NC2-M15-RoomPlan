//
//  StoryEditorView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/15/26.
//

import SwiftUI
import SwiftData
import PhotosUI

//스캔한 공간을 인스타그램 스토리처럼 꾸미는 화면
//3D 모델을 돌려서 각도를 맞추고, 오른쪽 도구에서 원하는 요소를 골라 추가함
struct StoryEditorView: View {
    let room: ScannedRoom
    let locationManager: LocationManager
    let onRescan: () -> Void
    let onExit: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var draft = StoryDraft()
    @State private var snapshotter = RoomSceneSnapshotter()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editingElementID: UUID?
    @State private var editingText: String = ""
    @State private var activeElementID: UUID?
    @State private var dragStartPosition: CGPoint?
    @State private var pinchStartScale: CGFloat?
    @State private var isDragging: Bool = false
    @State private var isOverTrash: Bool = false
    @State private var showHint: Bool = true
    @State private var showExitDialog: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var showSaveFailedAlert: Bool = false

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { proxy in
                canvas(size: StoryLayout.size(fitting: proxy.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            TextButtonRoundedRectangle(text: "저장") {
                save()
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.black.ignoresSafeArea())
        //텍스트를 입력할 때 키보드 때문에 카드 크기가 바뀌지 않도록 함
        .ignoresSafeArea(.keyboard)
        .overlay {
            if editingElementID != nil {
                textInputOverlay
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation {
                showHint = false
            }
        }
        .onChange(of: selectedPhoto) {
            Task {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    draft.setBackground(UIImage(data: data))
                } else {
                    print("Failed to load the image")
                }
            }
        }
        .confirmationDialog("편집을 그만두시겠습니까?", isPresented: $showExitDialog, titleVisibility: .visible) {
            Button {
                onRescan()
            } label: {
                Text("다시 스캔하기")
            }

            Button(role: .destructive) {
                onExit()
            } label: {
                Text("나가기")
            }

            Button(role: .cancel) {
            } label: {
                Text("취소")
            }
        }
        .alert("저장되었습니다.", isPresented: $showSavedAlert) {
            Button {
                onExit()
            } label: {
                Text("확인")
            }
        }
        .alert("저장하지 못했습니다.", isPresented: $showSaveFailedAlert) {
            Button {
            } label: {
                Text("확인")
            }
        }
    }
}

// MARK: - Canvas
private extension StoryEditorView {
    func canvas(size: CGSize) -> some View {
        let unit = size.width / StoryLayout.referenceWidth

        return ZStack {
            StoryBackgroundView(image: draft.background, preset: draft.backgroundPreset)

            RoomSceneView(roomScene: room.roomScene, snapshotter: snapshotter)

            ForEach(draft.elements) { element in
                elementView(element, canvasSize: size, unit: unit)
            }

            if isDragging {
                trashView(unit: unit)
                    .position(trashCenter(in: size, unit: unit))
            } else {
                controls
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 20 * unit))
        .coordinateSpace(name: "canvas")
    }

    func elementView(_ element: StoryElement, canvasSize: CGSize, unit: CGFloat) -> some View {
        StoryElementView(element: element, furniture: room.furniture, unit: unit)
            .scaleEffect(element.scale)
            .opacity(elementOpacity(element))
            .contentShape(Rectangle())
            .onTapGesture {
                beginEditing(element)
            }
            .gesture(dragGesture(for: element, canvasSize: canvasSize, unit: unit))
            .simultaneousGesture(pinchGesture(for: element))
            .zIndex(element.id == activeElementID ? 1 : 0)
            .position(x: element.position.x * canvasSize.width, y: element.position.y * canvasSize.height)
    }

    func elementOpacity(_ element: StoryElement) -> Double {
        if element.id == editingElementID {
            return 0
        }
        if element.id == activeElementID && isOverTrash {
            return 0.4
        }
        return 1
    }

    //상단 닫기 버튼, 오른쪽 도구 모음, 안내 문구
    var controls: some View {
        VStack {
            HStack(alignment: .top) {
                toolButton("xmark", label: "닫기") {
                    showExitDialog = true
                }

                Spacer()

                VStack(spacing: 12) {
                    toolButton("textformat", label: "텍스트") {
                        beginEditing(draft.add(.text))
                    }

                    toolButton("mappin.and.ellipse", label: "장소", isOn: draft.element(of: .location) != nil) {
                        beginEditing(draft.element(of: .location) ?? draft.add(.location))
                    }

                    toolButton("calendar", label: "날짜", isOn: draft.element(of: .date) != nil) {
                        toggle(.date, text: Date.now.cardDateString)
                    }

                    toolButton("sofa", label: "가구", isOn: draft.element(of: .furniture) != nil) {
                        toggle(.furniture)
                    }
                    .disabled(room.furniture.isEmpty)
                    .opacity(room.furniture.isEmpty ? 0.4 : 1)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        toolIcon("photo", isOn: draft.background != nil)
                    }
                    .accessibilityLabel(Text("배경 사진"))

                    toolButton("paintpalette", label: "배경 색상") {
                        draft.nextBackgroundPreset()
                    }
                }
            }

            Spacer()

            if showHint {
                Text("모델을 돌려 각도를 맞추고, 오른쪽에서 요소를 추가해보세요.")
                    .font(.footnote)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .padding(12)
    }

    func toolButton(_ systemImage: String, label: LocalizedStringKey, isOn: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolIcon(systemImage, isOn: isOn)
        }
        .accessibilityLabel(Text(label))
    }

    func toolIcon(_ systemImage: String, isOn: Bool) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isOn ? Color.black : Color.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(isOn ? Color.white : Color.black.opacity(0.4)))
    }

    func trashView(unit: CGFloat) -> some View {
        Image(systemName: "trash")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(width: 52, height: 52)
            .background(Circle().fill(isOverTrash ? Color.red : Color.black.opacity(0.5)))
            .scaleEffect(isOverTrash ? 1.2 : 1)
            .animation(.easeOut(duration: 0.15), value: isOverTrash)
    }

    func trashCenter(in size: CGSize, unit: CGFloat) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height - 56 * unit)
    }
}

// MARK: - Gestures
private extension StoryEditorView {
    //요소를 드래그해서 옮기고, 휴지통 위에서 놓으면 삭제
    func dragGesture(for element: StoryElement, canvasSize: CGSize, unit: CGFloat) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                if dragStartPosition == nil {
                    dragStartPosition = element.position
                    activeElementID = element.id
                    isDragging = true
                }
                guard let start = dragStartPosition else { return }

                draft.update(id: element.id) {
                    $0.position = CGPoint(
                        x: min(max(start.x + value.translation.width / canvasSize.width, 0), 1),
                        y: min(max(start.y + value.translation.height / canvasSize.height, 0), 1)
                    )
                }

                let trash = trashCenter(in: canvasSize, unit: unit)
                isOverTrash = hypot(value.location.x - trash.x, value.location.y - trash.y) < 44
            }
            .onEnded { _ in
                if isOverTrash {
                    draft.remove(id: element.id)
                }
                dragStartPosition = nil
                isDragging = false
                isOverTrash = false
            }
    }

    //두 손가락으로 요소의 크기를 조절
    func pinchGesture(for element: StoryElement) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if pinchStartScale == nil {
                    pinchStartScale = element.scale
                    activeElementID = element.id
                }
                guard let start = pinchStartScale else { return }

                draft.update(id: element.id) {
                    $0.scale = min(max(start * value.magnification, 0.4), 4)
                }
            }
            .onEnded { _ in
                pinchStartScale = nil
            }
    }
}

// MARK: - Text Input
private extension StoryEditorView {
    var textInputOverlay: some View {
        let kind = editingElementID.flatMap { draft.element(id: $0)?.kind } ?? .text

        return ZStack {
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    finishEditing()
                }

            VStack {
                HStack {
                    Spacer()

                    Button {
                        finishEditing()
                    } label: {
                        Text("완료")
                            .bold()
                            .foregroundStyle(Color.white)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if kind == .location {
                        Image("locationpin")
                            .resizable()
                            .frame(width: 17, height: 21)
                    }

                    TextField(text: $editingText, axis: kind == .text ? .vertical : .horizontal) {
                        Group {
                            if kind == .location {
                                Text("장소를 입력하세요.")
                            } else {
                                Text("텍스트를 입력하세요.")
                            }
                        }
                        .foregroundStyle(Color.white.opacity(0.6))
                    }
                    //장소는 핀 아이콘과 붙어 있도록 입력한 내용만큼의 너비를 사용
                    .fixedSize(horizontal: kind == .location, vertical: false)
                    .font(.system(size: kind == .text ? 28 : 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        finishEditing()
                    }
                    .onAppear {
                        //입력창이 나타난 뒤에 포커스를 줘야 키보드가 올라옴
                        isTextFieldFocused = true
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    func beginEditing(_ element: StoryElement) {
        guard element.kind == .text || element.kind == .location else { return }
        editingText = element.text
        editingElementID = element.id
    }

    //내용을 모두 지우면 요소도 삭제
    func finishEditing() {
        guard let id = editingElementID else { return }
        let text = editingText.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            draft.remove(id: id)
        } else {
            draft.update(id: id) { $0.text = text }
        }

        isTextFieldFocused = false
        editingElementID = nil
    }

    //날짜, 가구처럼 하나만 있는 요소는 버튼으로 추가하거나 제거
    func toggle(_ kind: StoryElement.Kind, text: String = "") {
        if let element = draft.element(of: kind) {
            draft.remove(id: element.id)
        } else {
            draft.add(kind, text: text)
        }
    }
}

// MARK: - Save
private extension StoryEditorView {
    func save() {
        guard let thumbnail = snapshotter.snapshot(),
              let record = draft.makeRecord(room: room, thumbnail: thumbnail, coordinate: locationManager.lastKnownLocation),
              modelContext.addRecord(record) else {
            showSaveFailedAlert = true
            return
        }
        showSavedAlert = true
    }
}
