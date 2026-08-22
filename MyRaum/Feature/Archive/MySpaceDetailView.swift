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
