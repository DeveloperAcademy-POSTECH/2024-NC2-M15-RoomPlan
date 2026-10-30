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
//record가 있으면 저장된 공간 카드를 수정하고, 없으면 새 공간 카드를 만듦
struct StoryEditorView: View {
    let room: ScannedRoom
    let record: SpaceRecord?
    let locationManager: LocationManager?
    let onRescan: (() -> Void)?
    let onExit: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var draft: StoryDraft
    //가구 배치 편집 - USDZ 파일로 연 카드처럼 가구를 구분할 수 없으면 nil
    @State private var furnitureEditor: FurnitureEditor?
    @State private var snapshotter = RoomSceneSnapshotter()
    @State private var camera = RoomSceneCamera()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editingElementID: UUID?
    @State private var editingText: String = ""
    @State private var activeElementID: UUID?
    @State private var dragStartPosition: CGPoint?
    @State private var pinchStartScale: CGFloat?
    @State private var isDragging: Bool = false
    @State private var isOverTrash: Bool = false
    @State private var elementSizes: [UUID: CGSize] = [:]
    @State private var alignmentGuides: Set<StoryAlignmentGuide> = []
    @State private var showHint: Bool = true
    @State private var showBackgroundPicker: Bool = false
    @State private var showFurnitureCatalog: Bool = false
    @State private var showExitDialog: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var showSaveFailedAlert: Bool = false
    @State private var isSaving: Bool = false

    @FocusState private var isTextFieldFocused: Bool

    init(
        room: ScannedRoom,
        record: SpaceRecord? = nil,
        locationManager: LocationManager? = nil,
        onRescan: (() -> Void)? = nil,
        onExit: @escaping () -> Void
    ) {
        self.room = room
        self.record = record
        self.locationManager = locationManager
        self.onRescan = onRescan
        self.onExit = onExit
        let draft = record.map(StoryDraft.init(record:)) ?? StoryDraft()
        _draft = State(initialValue: draft)
        _furnitureEditor = State(initialValue: room.roomScene.furniture.map { FurnitureEditor(layer: $0, draft: draft) })
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { proxy in
                canvas(size: StoryLayout.size(fitting: proxy.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            TextButtonRoundedRectangle(text: "저장") {
                save()
            }
            .disabled(isSaving)
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
            } else if isSaving {
                //가구 배치를 바꾼 경우 USDZ 파일을 다시 만드는 동안 기다림
                ProgressView()
                    .tint(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3).ignoresSafeArea())
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation {
                showHint = false
            }
        }
        //요소를 휴지통 위로 가져가면 놓았을 때 삭제된다는 것을 햅틱으로 알려줌
        .onChange(of: isOverTrash) {
            if isOverTrash {
                HapticManager.tap()
            }
        }
        //요소가 새 기준선에 맞춰지면 햅틱으로 알려줌
        .onChange(of: alignmentGuides) { oldGuides, newGuides in
            if !newGuides.subtracting(oldGuides).isEmpty {
                HapticManager.selection()
            }
        }
        .onChange(of: selectedPhoto) {
            guard let item = selectedPhoto else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    draft.setBackground(image)
                } else {
                    print("Failed to load the image")
                }
                //같은 사진을 다시 선택해도 반영되도록 선택 상태를 초기화
                selectedPhoto = nil
            }
        }
        //가구를 모두 지우면 빈 가구 요소가 남지 않도록 함께 지움
        .onChange(of: furniture.isEmpty) {
            if furniture.isEmpty, let element = draft.element(of: .furniture) {
                draft.remove(id: element.id)
            }
        }
        .sheet(isPresented: $showBackgroundPicker) {
            StoryBackgroundPicker(draft: draft, selectedPhoto: $selectedPhoto)
        }
        .sheet(isPresented: $showFurnitureCatalog) {
            FurnitureCatalogSheet { source in
                furnitureEditor?.add(source)
            }
        }
        .confirmationDialog("편집을 그만두시겠습니까?", isPresented: $showExitDialog, titleVisibility: .visible) {
            if let onRescan {
                Button {
                    onRescan()
                } label: {
                    Text("다시 스캔하기")
                }
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

            RoomSceneView(roomScene: room.roomScene, snapshotter: snapshotter, furnitureEditor: furnitureEditor, camera: camera)

            ForEach(draft.elements) { element in
                elementView(element, canvasSize: size, unit: unit)
            }

            if isDragging && !isOverTrash {
                StoryAlignmentGuideOverlay(guides: alignmentGuides, canvasSize: size)
            }

            if isDragging {
                trashView(unit: unit)
                    .position(trashCenter(in: size, unit: unit))
            } else {
                controls
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: StoryLayout.cornerRadius))
        .coordinateSpace(name: "canvas")
    }

    func elementView(_ element: StoryElement, canvasSize: CGSize, unit: CGFloat) -> some View {
        StoryElementView(element: element, furniture: furniture, unit: unit)
            //기준선에 맞출 때 요소의 가장자리 위치를 알기 위해 크기를 저장
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                elementSizes[element.id] = size
            }
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
            //가구 배치를 편집하는 동안에는 가구를 터치할 수 있도록 요소의 터치를 막음
            .allowsHitTesting(!isArranging)
    }

    var isArranging: Bool {
        furnitureEditor?.isEditing == true
    }

    //가구를 추가하거나 지운 결과까지 반영한 가구 목록
    var furniture: [FurnitureCategory] {
        room.furniture(applying: draft.arrangement)
    }

    func elementOpacity(_ element: StoryElement) -> Double {
        if isArranging {
            return 0.25
        }
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
                    if !isArranging {
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
                        .disabled(furniture.isEmpty)
                        .opacity(furniture.isEmpty ? 0.4 : 1)

                        toolButton("photo.on.rectangle", label: "배경 설정") {
                            showBackgroundPicker = true
                        }
                    }

                    //RoomPlan 원본 데이터가 없어서 USDZ 파일로 연 카드는 가구를 구분할 수 없으므로 비활성화
                    let canArrange = furnitureEditor != nil
                    toolButton("move.3d", label: "가구 배치", isOn: isArranging) {
                        toggleArranging()
                    }
                    .disabled(!canArrange)
                    .opacity(canArrange ? 1 : 0.4)

                    if isArranging {
                        toolButton("plus", label: "가구 추가") {
                            showFurnitureCatalog = true
                        }
                    }

                    //공간을 옮기거나 확대/축소해서 화면 가운데에서 벗어나면 다시 가운데로 가져오는 버튼
                    if camera.isOffCenter {
                        toolButton("scope", label: "가운데로") {
                            camera.recenter()
                        }
                        .transition(.opacity)
                    }
                }
            }

            Spacer()

            if isArranging {
                arrangingControls
            } else if showHint {
                hintLabel("모델을 돌려 각도를 맞추고, 오른쪽에서 요소를 추가해보세요.")
            }
        }
        .padding(12)
    }

    //가구 배치 편집 중에 보여주는 안내 문구와 선택된 가구의 회전, 되돌리기, 삭제 버튼
    var arrangingControls: some View {
        VStack(spacing: 10) {
            if let furnitureEditor, furnitureEditor.selectedID != nil {
                HStack(spacing: 8) {
                    arrangingButton("rotate.right", label: "90° 회전") {
                        furnitureEditor.rotateSelectedQuarter()
                    }

                    //가구 목록에서 추가한 가구는 되돌아갈 원래 위치가 없음
                    if !furnitureEditor.isSelectedAdded {
                        arrangingButton("arrow.uturn.backward", label: "원래 위치로") {
                            furnitureEditor.resetSelected()
                        }
                        .disabled(!furnitureEditor.isSelectedMoved)
                        .opacity(furnitureEditor.isSelectedMoved ? 1 : 0.4)
                    }

                    arrangingButton("trash", label: "삭제") {
                        furnitureEditor.removeSelected()
                    }
                }

                hintLabel("두 손가락으로 돌려서 방향을 바꿔보세요.")
            } else if furnitureEditor?.layer.nodes.isEmpty == true {
                hintLabel("오른쪽의 + 버튼으로 가구를 추가해보세요.")
            } else {
                hintLabel("가구를 탭해서 선택하고 드래그해서 옮겨보세요.")
            }
        }
        .transition(.opacity)
    }

    func hintLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.5)))
            .transition(.opacity)
            .allowsHitTesting(false)
    }

    func arrangingButton(_ systemImage: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            Label(label, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.5)))
        }
    }

    func toolButton(_ systemImage: String, label: LocalizedStringKey, isOn: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
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

                //가운데나 여백 기준선 가까이 오면 기준선에 맞춤
                let center = CGPoint(
                    x: start.x * canvasSize.width + value.translation.width,
                    y: start.y * canvasSize.height + value.translation.height
                )
                let baseSize = elementSizes[element.id] ?? .zero
                let elementSize = CGSize(width: baseSize.width * element.scale, height: baseSize.height * element.scale)
                let snapped = StoryAlignmentSnapper.snap(center: center, elementSize: elementSize, canvasSize: canvasSize, unit: unit)
                alignmentGuides = snapped.guides

                draft.update(id: element.id) {
                    $0.position = CGPoint(
                        x: min(max(snapped.center.x / canvasSize.width, 0), 1),
                        y: min(max(snapped.center.y / canvasSize.height, 0), 1)
                    )
                }

                let trash = trashCenter(in: canvasSize, unit: unit)
                isOverTrash = hypot(value.location.x - trash.x, value.location.y - trash.y) < 44
            }
            .onEnded { _ in
                if isOverTrash {
                    HapticManager.notify(.success)
                    draft.remove(id: element.id)
                    elementSizes[element.id] = nil
                }
                dragStartPosition = nil
                isDragging = false
                isOverTrash = false
                alignmentGuides = []
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
                        HapticManager.tap()
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

    //가구 배치 편집을 켜거나 끔 - 끄면 가구 선택도 해제됨
    func toggleArranging() {
        guard let furnitureEditor else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            furnitureEditor.setEditing(!furnitureEditor.isEditing)
            showHint = false
        }
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
        guard !isSaving else { return }
        //선택된 가구의 하이라이트가 썸네일에 찍히지 않도록 편집을 끝냄
        furnitureEditor?.setEditing(false)
        guard let thumbnail = snapshotter.snapshot() else {
            showSaveFailedAlert = true
            return
        }
        let cameraPose = snapshotter.cameraPose()
        
        isSaving = true
        Task { @MainActor in
            let isSaved: Bool
            if let record {
                let isApplied = await draft.apply(to: record, room: room, thumbnail: thumbnail, cameraPose: cameraPose)
                isSaved = isApplied && modelContext.saveChanges()
                if !isSaved {
                    //저장에 실패하면 카드에 반영한 내용을 되돌림
                    modelContext.rollback()
                }
            } else if let newRecord = await draft.makeRecord(room: room, thumbnail: thumbnail, cameraPose: cameraPose, coordinate: locationManager?.lastKnownLocation) {
                isSaved = modelContext.addRecord(newRecord)
            } else {
                isSaved = false
            }
            isSaving = false
            
            if isSaved {
                HapticManager.notify(.success)
                showSavedAlert = true
            } else {
                HapticManager.notify(.error)
                showSaveFailedAlert = true
            }
        }
    }
}
