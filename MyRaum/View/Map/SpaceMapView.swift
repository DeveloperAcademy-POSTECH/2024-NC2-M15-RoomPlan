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
    @State private var camera = MapCameraTracker()

    var body: some View {
        let pins = mapPins

        MapReader { proxy in
            //카메라 위치를 바인딩하지 않아야 지도를 움직일 때마다 카드 이미지를 다시 그리지 않음
            Map(initialPosition: .automatic) {
                //MapKit은 겹친 카드를 그리는 순서와 탭을 받는 카드가 서로 다를 수 있어서
                //카드는 MapPinLayer에서 직접 그리고, 지도에는 처음 화면에 카드가 모두 보이도록 빈 영역만 둠
                ForEach(pins) { pin in
                    Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                        Color.clear
                            .frame(width: MapPinView.width, height: MapPinView.height)
                    }
                    .annotationTitles(.hidden)
                }

                UserAnnotation()
            }
            .onMapCameraChange(frequency: .continuous) {
                camera.version &+= 1
            }
            .overlay {
                MapPinLayer(pins: pins, proxy: proxy, camera: camera) { pin in
                    HapticManager.tap()
                    selectedPin = pin
                }
            }
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
        //지도는 스크롤 뷰가 아니라 scrollEdgeEffectStyle이 적용되지 않으므로
        //다른 탭 화면처럼 상단 툴바 아래가 서서히 불투명해지도록 그라데이션을 직접 덮음
        .overlay(alignment: .top) {
            TopEdgeGradient()
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

//지도가 움직일 때마다 카드 위치를 다시 계산하기 위한 값
//카드 레이어만 이 값을 읽어서 지도 화면 전체가 다시 그려지지 않도록 함
@Observable
private final class MapCameraTracker {
    var version = 0
}

//지도 위에 카드들을 직접 그리는 레이어
//화면 아래쪽에 있는 카드를 앞에 그리고, 겹친 곳을 탭하면 제일 앞에 보이는 카드가 열림
private struct MapPinLayer: View {
    let pins: [MapPin]
    let proxy: MapProxy
    let camera: MapCameraTracker
    let onSelect: (MapPin) -> Void

    var body: some View {
        let _ = camera.version
        let placed = placedPins

        ZStack {
            ForEach(Array(placed.enumerated()), id: \.element.pin.id) { index, item in
                MapPinView(pin: item.pin, showsTitle: !isCovered(index, in: placed))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(item.pin)
                    }
                    .position(x: item.bottom.x, y: item.bottom.y - MapPinView.height / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    //화면에 표시할 카드와 카드 아래 끝의 화면 위치 - 위에서 아래 순서로 정렬해서 아래쪽 카드가 앞에 그려짐
    private var placedPins: [(pin: MapPin, bottom: CGPoint)] {
        pins
            .compactMap { pin in
                proxy.convert(pin.coordinate, to: .local).map { (pin, $0) }
            }
            .sorted { $0.bottom.y < $1.bottom.y }
    }

    //앞에 있는 카드에 가려지는 카드는 장소명을 숨겨서 글자가 겹치지 않도록 함
    private func isCovered(_ index: Int, in placed: [(pin: MapPin, bottom: CGPoint)]) -> Bool {
        let frame = MapPinView.frame(bottom: placed[index].bottom)
        return placed[(index + 1)...].contains { MapPinView.frame(bottom: $0.bottom).intersects(frame) }
    }
}

//지도 위의 작은 카드 썸네일
private struct MapPinView: View {
    let pin: MapPin
    var showsTitle: Bool = false

    static let width: CGFloat = 46
    static let height: CGFloat = width / StoryLayout.aspectRatio + arrowHeight
    private static let arrowHeight: CGFloat = 8

    //카드 아래 끝의 화면 위치를 기준으로 카드가 차지하는 영역
    static func frame(bottom: CGPoint) -> CGRect {
        CGRect(x: bottom.x - width / 2, y: bottom.y - height, width: width, height: height)
    }

    private var width: CGFloat { Self.width }

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
                .frame(height: Self.arrowHeight)
                .offset(y: -2)
        }
        //장소명은 카드 아래에 붙여서 표시 (카드 위치 계산에는 포함하지 않음)
        .overlay(alignment: .bottom) {
            Color.clear
                .frame(height: 0)
                .overlay(alignment: .top) {
                    if showsTitle {
                        Text(pin.title)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(Color.primary)
                            .shadow(color: Color(.systemBackground), radius: 1)
                            .shadow(color: Color(.systemBackground), radius: 1)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.top, 2)
                    }
                }
                .allowsHitTesting(false)
        }
    }

    //신규 카드와 이전 카드 모두 배경 위에 모델만 표시
    @ViewBuilder
    var thumbnail: some View {
        switch pin.card {
        case .record(let record):
            SpaceThumbnailView(record: record, width: width, showsTitle: false, cornerRadius: 0)
        case .legacy(let space):
            SpaceThumbnailView(space: space, width: width, showsTitle: false, cornerRadius: 0)
        }
    }
}

#Preview {
    NavigationStack {
        SpaceMapView()
    }
    .modelContainer(for: [SpaceRecord.self, SpaceData.self], inMemory: true)
}

//화면 맨 위에서 상단 툴바 아래까지 서서히 투명해지는 그라데이션
//불투명하게 유지하는 구간 없이 투명도가 코사인 곡선을 따라 변하도록 해서 어디에도 경계선이 보이지 않음
private struct TopEdgeGradient: View {
    //툴바 아래로 그라데이션이 이어지는 길이
    private let fadeHeight: CGFloat = 60

    //화면 맨 위의 불투명도 (지도가 비쳐 보이도록 완전히 덮지 않음)
    private let maxOpacity: Double = 0.7

    //곡선을 표현하는 색 지점의 개수
    private let stopCount = 16

    var body: some View {
        GeometryReader { proxy in
            //화면 맨 위에서 툴바 아래까지의 거리
            let barHeight = proxy.frame(in: .global).minY + proxy.safeAreaInsets.top
            let totalHeight = barHeight + fadeHeight

            LinearGradient(
                stops: stops,
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: totalHeight)
            .offset(y: -barHeight)
        }
        .allowsHitTesting(false)
    }

    //화면 맨 위부터 끝까지 코사인 곡선으로 투명해짐
    private var stops: [Gradient.Stop] {
        let background = Color(.systemBackground)

        return (0...stopCount).map { index in
            let progress = Double(index) / Double(stopCount)
            let opacity = maxOpacity * (1 + cos(.pi * progress)) / 2
            return .init(color: background.opacity(opacity), location: progress)
        }
    }
}
