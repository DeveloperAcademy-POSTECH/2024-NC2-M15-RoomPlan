//
//  SpaceMapView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/16/26.
//

import SwiftUI
import SwiftData
import MapKit

//공간 카드를 스캔한 위치에 보여주는 지도 화면
//카드를 탭하면 상세 화면이 열림
struct SpaceMapView: View {
    @Query(sort: \SpaceRecord.createdAt, order: .reverse) private var records: [SpaceRecord]
    @Query private var legacySpaces: [SpaceData]

    @State private var selectedPin: MapPin?

    var body: some View {
        let pins = mapPins

        //카메라 위치를 바인딩하지 않아야 지도를 움직일 때마다 카드 이미지를 다시 그리지 않음
        Map(initialPosition: .automatic) {
            ForEach(pins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate, anchor: .bottom) {
                    MapPinView(pin: pin)
                        .onTapGesture {
                            selectedPin = pin
                        }
                }
            }

            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay {
            if pins.isEmpty {
                emptyView
            }
        }
        .customNavigationBar(title: "지도", showsBackButton: false)
        .sheet(item: $selectedPin) { pin in
            switch pin.card {
            case .record(let record):
                SpaceRecordDetailView(record: record)
            case .legacy(let space):
                MySpaceDetailView(space: space)
            }
        }
    }
}

private extension SpaceMapView {
    //위치 정보가 있는 공간 카드만 표시 (이전 카드 포함)
    var mapPins: [MapPin] {
        let recordPins = records.compactMap { record in
            record.coordinate.map { MapPin(card: .record(record), coordinate: $0) }
        }
        let legacyPins = legacySpaces.compactMap { space in
            space.coordinate.map { MapPin(card: .legacy(space), coordinate: $0) }
        }
        return recordPins + legacyPins
    }

    var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.title)

            Text("위치 정보가 있는 공간 카드가 없습니다.")
                .bold()

            Text("위치 권한을 허용하고 공간을 스캔하면 지도에 표시됩니다.")
                .font(.footnote)
                .foregroundStyle(Color.gray)
        }
        .multilineTextAlignment(.center)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
        .padding(.horizontal, 30)
    }
}

//지도에 표시되는 공간 카드
struct MapPin: Identifiable {
    enum Card {
        case record(SpaceRecord)
        case legacy(SpaceData)
    }

    let card: Card
    let coordinate: CLLocationCoordinate2D

    var id: String {
        switch card {
        case .record(let record): "record-\(record.id)"
        case .legacy(let space): "legacy-\(space.id)"
        }
    }

    var title: String {
        switch card {
        case .record(let record): record.title
        case .legacy(let space): space.comment
        }
    }
}

//지도 위의 작은 카드 썸네일
private struct MapPinView: View {
    let pin: MapPin

    private let width: CGFloat = 46

    var body: some View {
        VStack(spacing: 0) {
            thumbnail
                .frame(width: width, height: width / StoryLayout.aspectRatio)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)

            //카드가 가리키는 위치 표시
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.white)
                .offset(y: -2)
        }
    }

    @ViewBuilder
    var thumbnail: some View {
        switch pin.card {
        case .record(let record):
            StoryCardView(record: record, width: width, cornerRadius: 0)
        case .legacy(let space):
            ZStack {
                if let background = space.backgroundImage {
                    Image(uiImage: background)
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.4))
                }
                if let model = space.modelImage {
                    Image(uiImage: model)
                        .resizable()
                        .scaledToFit()
                }
            }
            .background(Color.gray)
        }
    }
}

#Preview {
    NavigationStack {
        SpaceMapView()
    }
    .modelContainer(for: [SpaceRecord.self, SpaceData.self], inMemory: true)
}
