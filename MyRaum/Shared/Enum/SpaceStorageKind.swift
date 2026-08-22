//
//  SpaceStorageKind.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//공간 데이터가 어떤 방식으로 저장되어 있는지 구분하는 값
enum SpaceStorageKind: String {
    //1.0.x에서 누끼 이미지로 저장된 카드
    case legacyImage
    //2.0에서 USDZ 3D 모델로 저장된 카드
    case usdz
}
