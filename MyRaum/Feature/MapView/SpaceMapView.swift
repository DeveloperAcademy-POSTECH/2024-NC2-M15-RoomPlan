//
//  SpaceMapView.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import SwiftUI
import SwiftData
import MapKit

//저장된 공간을 지도에 모아 보여주는 화면 (FR-10)
struct SpaceMapView: View {
    @Environment(\.dismiss) private var dismiss
    
    //레거시 카드도 위경도를 갖고 있으므로 함께 표시한다
    @Query(sort: \SpaceData.createdAt, order: .reverse) private var spaceData: [SpaceData]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleSpan = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    @State private var selectedSpace: SpaceData? = nil
    @State private var didSetInitialRegion: Bool = false
    
    var body: some View {
        Group {
            if locatedSpaces.isEmpty {
                emptyView
            } else {
                map
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .bold()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("지도에서 보기")
                    .bold()
            }
        }
        .sheet(item: $selectedSpace) { space in
            //탭하면 3D 상세뷰로 진입한다
            if space.kind == .usdz {
                MySpaceDetailView(space: space)
            } else {
                LegacyDetailView(space: space)
            }
        }
    }
}

private extension SpaceMapView {
    //위치 정보가 있는 공간만 지도에 올린다
    var locatedSpaces: [SpaceData] {
        spaceData.filter(\.hasLocation)
    }
    
    var annotations: [SpaceAnnotation] {
        locatedSpaces.map { space in
            SpaceAnnotation(
                id: space.id,
                coordinate: CLLocationCoordinate2D(latitude: space.latitude, longitude: space.longitude),
                structureID: space.structureID
            )
        }
    }
    
    var clusters: [SpaceCluster] {
        SpaceClusterer.cluster(annotations, in: visibleSpan)
    }
    
    var emptyView: some View {
        VStack {
            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundStyle(Color.gray)
                .padding()
            
            Text("위치 정보가 있는 공간이 없습니다.")
                .font(.title3)
                .bold()
        }
    }
    
    var map: some View {
        Map(position: $cameraPosition) {
            ForEach(clusters) { cluster in
                Annotation("", coordinate: cluster.coordinate) {
                    marker(for: cluster)
                }
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleSpan = context.region.span
        }
        .onAppear {
            guard didSetInitialRegion == false else { return }
            didSetInitialRegion = true
            
            //저장된 공간이 모두 보이도록 처음 영역을 맞춘다
            if let region = SpaceClusterer.boundingRegion(for: annotations) {
                cameraPosition = .region(region)
                visibleSpan = region.span
            }
        }
    }
    
    //마커 하나. 묶여 있으면 개수 배지를, 단독이면 썸네일을 보여준다
    @ViewBuilder
    func marker(for cluster: SpaceCluster) -> some View {
        if cluster.isSingle, let annotation = cluster.first {
            Button {
                selectedSpace = space(for: annotation.id)
            } label: {
                thumbnailMarker(for: annotation.id)
            }
        } else {
            Button {
                zoomIn(on: cluster)
            } label: {
                clusterMarker(count: cluster.count)
            }
        }
    }
    
    //마커마다 실시간 3D 렌더링은 성능 부담이 크므로 저장된 썸네일을 사용한다
    @ViewBuilder
    func thumbnailMarker(for id: UUID) -> some View {
        let imageData = space(for: id)?.markerImageData
        
        ZStack {
            Circle()
                .foregroundStyle(Color.white)
                .frame(width: 46, height: 46)
                .shadow(radius: 3)
            
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.gray)
            }
        }
    }
    
    func clusterMarker(count: Int) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(Color.black)
                .frame(width: 46, height: 46)
                .shadow(radius: 3)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 46, height: 46)
            
            Text("\(count)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
        }
    }
    
    func space(for id: UUID) -> SpaceData? {
        locatedSpaces.first { $0.id == id }
    }
    
    //묶인 마커를 탭하면 그 안이 펼쳐지도록 확대한다
    func zoomIn(on cluster: SpaceCluster) {
        let span = MKCoordinateSpan(
            latitudeDelta: max(visibleSpan.latitudeDelta / 3, 0.002),
            longitudeDelta: max(visibleSpan.longitudeDelta / 3, 0.002)
        )
        
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: cluster.coordinate, span: span))
        }
        visibleSpan = span
    }
}
