//
//  SpaceCardMapView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI
import MapKit

//공간 카드 시트의 상단 - 왼쪽에서 카드 앞면(카드)과 뒷면(지도)을 고르고, 오른쪽 버튼으로 닫음
//신규 카드(SpaceRecordDetailView)와 이전 카드(MySpaceDetailView)에서 함께 사용
struct SpaceCardSheetHeader: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var cardFlipped: Bool

    var body: some View {
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
                HapticManager.tap()
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
        .onChange(of: cardFlipped) {
            HapticManager.selection()
        }
    }
}

//공간 카드의 뒷면 - 장소의 위치 정보, 장소명, 날짜 등이 노출됨
struct SpaceCardMapView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let coordinate: CLLocationCoordinate2D?
    let date: String?

    var body: some View {
        RoundedRectangle(cornerRadius: StoryLayout.cornerRadius)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 315, height: 560)
            .overlay(
                ZStack {
                    Map(bounds: MapCameraBounds(minimumDistance: 600)) {
                        if let coordinate {
                            Marker(title, coordinate: coordinate)
                                .tint(colorScheme == .dark ? .white : .black)
                        }
                    }
                    .frame(width: 315, height: 560)
                    .clipShape(RoundedRectangle(cornerRadius: StoryLayout.cornerRadius))

                    VStack {
                        Label(title, systemImage: "map")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(.top, 30)

                        Spacer()

                        //위치 권한 없이 저장된 카드는 지도에 표시할 위치가 없음
                        if coordinate == nil {
                            Text("위치 정보가 없습니다.")
                                .font(.footnote)
                                .bold()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.regularMaterial))

                            Spacer()
                        }

                        if let date {
                            SpaceCardFooter(date: date, dateColor: colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                        }
                    }
                }
            )
    }
}

#Preview {
    SpaceCardMapView(title: "포항", coordinate: CLLocationCoordinate2D(latitude: 36.019, longitude: 129.343), date: "2026.10.17")
}
