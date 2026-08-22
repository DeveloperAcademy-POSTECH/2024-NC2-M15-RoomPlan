//
//  MySpaceDetailView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//저장된 공간의 상세 정보를 확인하고 이미지 저장 및 공유가 가능한 뷰
struct MySpaceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppContainer.self) private var container
    
    let space: SpaceData
    
    @State private var card: UIImage = UIImage()
    @State private var showSavedAlert: Bool = false
    @State private var cardFlipped: Bool = false
    @State private var isUpdatingVisibility: Bool = false
    @State private var showPublicWarning: Bool = false
    
    //Documents/Models 아래에 저장된 USDZ 경로
    private var modelURL: URL? {
        guard let modelFileName = space.modelFileName else { return nil }
        return container.modelFileStore.url(forFileName: modelFileName)
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker(selection: $cardFlipped) {
                    Label(" 카드", systemImage: "square.2.layers.3d.top.filled").tag(false)
                    Label(" 지도", systemImage: "square.2.layers.3d.bottom.filled").tag(true)
                } label: {
                    Text("Card View")
                }
                .pickerStyle(.menu)
                .padding()
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "x.circle")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .bold()
                }
                .padding()
            }
            
            MySpaceCardView(space: space, modelURL: modelURL, cardFlipped: $cardFlipped)
                .onAppear(perform: {
                    //3D 뷰는 이미지로 캡쳐되지 않으므로 공유용 정지 카드를 따로 그린다
                    card = SpaceShareCardView(space: space).snapshot()
                })
            
            spaceInfoBadges
            
            visibilitySection
            
            Spacer()
            
            HStack(spacing: 16) {
                LabelButtonRoundedRectangle(text: "이미지 저장", image: "photo.badge.arrow.down") {
                    UIImageWriteToSavedPhotosAlbum(card, nil, nil, nil)
                    showSavedAlert = true
                }
                .frame(width: 150)
                .alert("이미지가 저장되었습니다.", isPresented: $showSavedAlert) {
                    Button {
                    } label: {
                        Text("확인")
                    }
                }
                
                ShareLink(item: Image(uiImage: card), preview: SharePreview("공간 카드 공유", icon: "AppIcon")) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.grayButtonStroke)
                        .frame(width: 150, height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(Color.grayButton)
                            
                            Label("공유", systemImage: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.white)
                        }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

private extension MySpaceDetailView {
    //공개 토글과 동기화 상태 (6B.8)
    var visibilitySection: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: Binding(
                    get: { space.isPublic },
                    set: { newValue in
                        if newValue {
                            //공개로 바꿀 때는 위치가 노출된다는 점을 먼저 경고한다
                            showPublicWarning = true
                        } else {
                            updateVisibility(to: false)
                        }
                    }
                )) {
                    Text("공개")
                        .font(.system(size: 15))
                }
                .disabled(isUpdatingVisibility)
            }
            
            HStack {
                syncStateLabel
                
                Spacer()
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 16)
        .alert("이 공간을 공개하시겠습니까?", isPresented: $showPublicWarning, actions: {
            Button(role: .cancel) {
            } label: {
                Text("취소")
            }
            
            Button {
                updateVisibility(to: true)
            } label: {
                Text("공개")
            }
        }, message: {
            Text("공개하면 이 공간의 위치가 다른 사용자에게 함께 보입니다.")
        })
    }
    
    @ViewBuilder
    var syncStateLabel: some View {
        switch space.sync {
        case .pending:
            Label("업로드 대기 중", systemImage: "arrow.clockwise.icloud")
                .font(.caption)
                .foregroundStyle(Color.gray)
        case .synced:
            Label("업로드 완료", systemImage: "checkmark.icloud")
                .font(.caption)
                .foregroundStyle(Color.gray)
        case .failed:
            Label("업로드 실패", systemImage: "exclamationmark.icloud")
                .font(.caption)
                .foregroundStyle(Color.red)
        case .localOnly:
            EmptyView()
        }
    }
    
    //공개 여부만 갱신한다. 원격 데이터를 삭제하지 않는다 (6B.9)
    func updateVisibility(to isPublic: Bool) {
        space.isPublic = isPublic
        container.spaceRepository.saveChanges()
        
        guard let remoteID = space.remoteID else {
            //아직 업로드되지 않았다면 다음 업로드에 값이 함께 올라간다
            return
        }
        
        isUpdatingVisibility = true
        
        Task {
            defer { isUpdatingVisibility = false }
            
            do {
                try await container.remoteSpaceRepository.updateIsPublic(remoteID: remoteID, isPublic: isPublic)
            } catch {
                print("Failed to update visibility: \(error)")
            }
        }
    }
    
    //면적·방 종류를 카드 아래에 배지로 노출
    @ViewBuilder
    var spaceInfoBadges: some View {
        HStack(spacing: 8) {
            if space.roomType != .unknown {
                badge(text: Text(LocalizedStringKey(space.roomType.displayNameKey)), systemImage: "square.split.bottomrightquarter")
            }
            
            if let floorAreaSqM = space.floorAreaSqM, floorAreaSqM > 0 {
                //면적 숫자는 번역 대상이 아니므로 그대로 출력한다
                badge(text: Text(verbatim: String(format: "%.1f m²", floorAreaSqM)), systemImage: "ruler")
            }
        }
        .padding(.top, 12)
    }
    
    func badge(text: Text, systemImage: String) -> some View {
        Label {
            text
        } icon: {
            Image(systemName: systemImage)
        }
            .font(.system(size: 14))
            .foregroundStyle(Color.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule().foregroundStyle(Color.grayButton.opacity(0.3))
            }
    }
}
