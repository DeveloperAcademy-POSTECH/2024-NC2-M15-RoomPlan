//
//  ScanEditorView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import PhotosUI

//스캔이 끝난 뒤 저장까지를 한 화면에서 마무리하는 편집 캔버스
//인스타 스토리처럼 카드가 항상 전체 화면 프리뷰로 존재한다
struct ScanEditorView: View {
    @Bindable var viewModel: ScanFlowViewModel
    let onClose: () -> Void
    
    @State private var typedComment: String = ""
    
    @FocusState private var commentFocused: Bool
    
    var body: some View {
        ZStack {
            //배경만 화면 끝까지 채우고, 편집 요소들은 안전 영역 안에 둔다
            Color.black
                .ignoresSafeArea()
            
            backgroundLayer
            
            VStack(spacing: 0) {
                HStack {
                    CloseScanButton(action: onClose)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ScanStepIndicator(step: .edit)
                    .padding(.top, 12)
                
                if viewModel.roomCountInStructure > 1 {
                    structureBadge
                }
                
                if viewModel.lowConfidenceCount > 0 {
                    lowConfidenceHint
                }
                
                commentLayer
                
                Spacer()
                
                modelLayer
                
                Spacer()
                
                dateLayer
                
                toolbar
            }
            
            if viewModel.isEditingComment {
                commentEditingOverlay
            }
        }
        .alert("저장되었습니다.", isPresented: $viewModel.showSavedSuccessAlert) {
            Button {
                viewModel.resetAfterSave()
                onClose()
            } label: {
                Text("확인")
            }
        }
        .alert("저장하지 못했습니다.", isPresented: $viewModel.showSavedFailureAlert) {
            Button {
            } label: {
                Text("확인")
            }
        }
    }
}

private extension ScanEditorView {
    var backgroundLayer: some View {
        Group {
            if let background = viewModel.background {
                Image(uiImage: background)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.4))
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }
    
    //구조에 몇 번째 방을 담고 있는지 알려 준다
    var structureBadge: some View {
        Text("\(viewModel.roomCountInStructure)번째 방")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule().foregroundStyle(Color.black.opacity(0.55))
            }
            .padding(.top, 12)
    }
    
    //신뢰도가 낮은 오브젝트가 있으면 더 스캔하도록 안내한다
    var lowConfidenceHint: some View {
        Button {
            viewModel.restartScanning()
        } label: {
            Label("이 영역을 더 스캔해 보세요.", systemImage: "exclamationmark.triangle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule().foregroundStyle(Color.black.opacity(0.55))
                }
        }
        .padding(.top, 12)
    }
    
    //장소명 — 탭하면 인라인으로 편집한다
    var commentLayer: some View {
        Button {
            typedComment = viewModel.comment
            viewModel.beginEditingComment()
        } label: {
            HStack {
                Image("locationpin")
                    .resizable()
                    .frame(width: 17, height: 21)
                
                Text(viewModel.comment.isEmpty ? "장소를 입력하세요." : viewModel.comment)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.comment.isEmpty ? Color.white.opacity(0.6) : Color.white)
            }
        }
        .padding(.top, 40)
    }
    
    var modelLayer: some View {
        Group {
            if let modelURL = viewModel.modelURL {
                Space3DView(modelURL: modelURL, resetToken: viewModel.modelResetToken)
            } else if let thumbnail = viewModel.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(maxHeight: 420)
    }
    
    @ViewBuilder
    var dateLayer: some View {
        if viewModel.showsDate {
            HStack {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .padding()
                    .opacity(0.4)
                
                Spacer()
                
                Text(viewModel.dateText)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.8))
                    .padding()
            }
            .padding(.horizontal, 8)
        }
    }
    
    //배경 · 장소명 · 날짜 토글 · 각도 리셋 · 저장
    var toolbar: some View {
        HStack(spacing: 22) {
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                toolbarIcon("photo")
            }
            .onChange(of: viewModel.selectedItem) {
                Task {
                    await viewModel.loadBackground()
                }
            }
            
            Button {
                typedComment = viewModel.comment
                viewModel.beginEditingComment()
            } label: {
                toolbarIcon("textformat")
            }
            
            Button {
                viewModel.toggleDate()
            } label: {
                toolbarIcon(viewModel.showsDate ? "calendar" : "calendar.badge.minus")
            }
            
            Button {
                viewModel.resetModelAngle()
            } label: {
                toolbarIcon("arrow.counterclockwise")
            }
            
            Spacer()
            
            //기존 구조에 방을 이어 붙인다 (8.1)
            Button {
                viewModel.addAnotherRoom()
            } label: {
                toolbarIcon("plus.rectangle.on.rectangle")
            }
            .accessibilityLabel(Text("방 추가하기"))
            
            Button {
                viewModel.saveSpaceData()
            } label: {
                Text("저장")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        Capsule().foregroundStyle(Color.white)
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    func toolbarIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 22))
            .foregroundStyle(Color.white)
            .frame(width: 34, height: 34)
    }
    
    //모달 대신 화면 위에서 바로 입력받는 오버레이
    var commentEditingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.endEditingComment(with: typedComment)
                }
            
            VStack(spacing: 16) {
                Text("공간에 대해서 기록하세요.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                
                TextField(text: $typedComment) {
                    Text("장소를 입력하세요.")
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .focused($commentFocused)
                .onSubmit {
                    viewModel.endEditingComment(with: typedComment)
                }
                //오버레이가 올라온 뒤에 포커스를 줘야 키보드가 뜬다
                .onAppear {
                    commentFocused = true
                }
                .padding(.horizontal, 40)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.horizontal, 40)
                
                Button {
                    viewModel.endEditingComment(with: typedComment)
                } label: {
                    Text("완료")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background {
                            Capsule().foregroundStyle(Color.white)
                        }
                }
            }
        }
    }
}
