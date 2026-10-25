//
//  UnsupportedDeviceView.swift
//  MyRaum
//
//  Created by Yune Cho on 6/13/24.
//

import SwiftUI

//RoomPlan을 지원하지 않는 기기일 경우 보여주는 화면
//앱을 사용할 수 없는 이유와 지원하는 기기, 확인 방법을 홈 화면과 같은 구성으로 안내함
struct UnsupportedDeviceView: View {
    //가로가 이 너비 이상이고 세로보다 길면(iPhone Duo를 가로로 펼친 경우 등) 로고와 안내를 좌우로 나눠 배치
    //세로로 길게 펼친 경우에는 접었을 때와 같은 배치를 사용
    private let wideLayoutWidth: CGFloat = 600

    //상단 안전 영역이 거의 없는 화면(iPhone Duo를 접은 경우 등)에서도 확보할 최소 상단 여백
    private let minimumTopMargin: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            //좌우를 나누는 기준은 안전 영역을 포함한 화면 전체 너비 (iPhone Duo의 힌지 위치)
            let screenWidth = proxy.size.width + insets.leading + insets.trailing

            Group {
                if screenWidth >= wideLayoutWidth && screenWidth > proxy.size.height {
                    wideLayout(screenWidth: screenWidth, insets: insets)
                } else {
                    narrowLayout
                }
            }
            .padding(.top, max(0, minimumTopMargin - insets.top))
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    //로고 아래에 안내 문구를 배치
    //한 화면에 모두 들어가도록 구성함
    //iPhone SE처럼 화면이 작으면 로고와 간격을 줄인 배치를 쓰고, 그래도 넘치면(글자 크기를 키운 경우 등) 스크롤되도록 함
    private var narrowLayout: some View {
        ViewThatFits(in: .vertical) {
            narrowContent(isCompact: false)

            narrowContent(isCompact: true)

            ScrollView {
                narrowContent(isCompact: true)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func narrowContent(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 8)
            
            logo
                .frame(width: isCompact ? 96 : 150)
                .padding(.bottom, isCompact ? 16 : 28)

            details(isCompact: isCompact)

            Spacer(minLength: 8)

            version
        }
        .padding(.horizontal, isCompact ? 24 : 30)
        .padding(.top, isCompact ? 8 : 24)
        .padding(.bottom, 8)
    }

    //화면 중앙(iPhone Duo를 펼쳤을 때의 힌지)을 기준으로 좌우를 나눠
    //왼쪽 가운데에 로고, 오른쪽에 안내 문구를 배치
    //컨텐츠는 안전 영역 안에만 그려지도록 각 영역의 너비에서 해당 쪽의 안전 영역을 뺌
    private func wideLayout(screenWidth: CGFloat, insets: EdgeInsets) -> some View {
        let half = screenWidth / 2

        return HStack(spacing: 0) {
            logo
                .frame(width: min(half * 0.6, 280))
                .frame(width: half - insets.leading)
                .frame(maxHeight: .infinity)

            ViewThatFits(in: .vertical) {
                wideDetails(isCompact: false)

                wideDetails(isCompact: true)

                ScrollView {
                    wideDetails(isCompact: true)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: half - insets.trailing)
        }
    }

    //안내 문구는 세로 가운데에, 버전 정보는 맨 아래에 배치
    private func wideDetails(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 16)

            details(isCompact: isCompact)

            Spacer(minLength: 8)

            version
        }
        //힌지에 글자가 걸치지 않도록 왼쪽에도 여백을 둠
        .padding(.horizontal, 30)
        .padding(.bottom, 8)
    }

    //홈 화면과 같은 로고 (라이트/다크 모드에 따라 색이 바뀜)
    private var logo: some View {
        Image("homelogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func details(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "iphone.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 12)
                
                Text("지원하지 않는 기기입니다.")
                    .font(isCompact ? .title3 : .title2)
                    .bold()
                    //영어처럼 문구가 긴 언어에서도 잘리지 않고 줄바꿈되도록 함
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .padding(.bottom, isCompact ? 4 : 8)
                
                Spacer()
            }

            Text("My Raum은 라이다(LiDAR) 센서로 공간을 3D로 스캔합니다. 이 기기에는 라이다 센서가 없어 앱을 사용할 수 없습니다.")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, isCompact ? 4 : 12)

            infoSection(title: "라이다가 필요한 이유", isCompact: isCompact) {
                infoRow(
                    systemImage: "cube.transparent",
                    title: "3D 공간 스캔",
                    message: "라이다 센서가 빛을 쏘아 벽, 문, 창문, 가구까지의 거리를 측정하고, 이를 바탕으로 공간의 3D 모델을 만듭니다.",
                    isCompact: isCompact
                )
            }

            infoSection(title: "지원하는 기기", isCompact: isCompact) {
                infoRow(
                    systemImage: "iphone",
                    title: "iPhone",
                    message: "iPhone 12 Pro, iPhone 12 Pro Max 및 이후 출시된 Pro, Pro Max 모델",
                    isCompact: isCompact
                )

                infoRow(
                    systemImage: "ipad",
                    title: "iPad",
                    message: "iPad Pro 11형(2세대), iPad Pro 12.9형(4세대) 및 이후 출시된 iPad Pro 모델",
                    isCompact: isCompact
                )
            }

            infoSection(title: "확인 방법", isCompact: isCompact) {
                infoRow(
                    systemImage: "camera.aperture",
                    title: "후면 카메라 확인",
                    message: "기기 뒷면 카메라 옆에 작고 검은 원 모양의 센서가 있다면 라이다를 지원하는 기기입니다.",
                    isCompact: isCompact
                )
            }
        }
    }

    private var version: some View {
        Text("[Version \(AppEnvironment.version)]")
            .foregroundStyle(Color.gray)
            .font(.caption)
            .frame(maxWidth: .infinity)
    }
}

private extension UnsupportedDeviceView {
    //내 정보 화면과 같은 형태의 섹션 (회색 제목 + 구분선이 있는 항목)
    func infoSection<T: View>(title: LocalizedStringKey, isCompact: Bool, @ViewBuilder items: () -> T) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 0) {
                items()
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
            }
        }
        .padding(.vertical, isCompact ? 3 : 6)
    }

    func infoRow(systemImage: String, title: LocalizedStringKey, message: LocalizedStringKey, isCompact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .bold()

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        //작은 화면에서는 항목 사이 간격을 줄임
        .padding(.vertical, isCompact ? 6 : 10)
    }
}

#Preview {
    UnsupportedDeviceView()
}
