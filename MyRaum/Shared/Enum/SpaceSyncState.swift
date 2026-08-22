//
//  SpaceSyncState.swift
//  MyRaum
//
//  Created by Yune Cho on 8/22/26.
//

import Foundation

//서버 동기화 상태
enum SpaceSyncState: String {
    //업로드 대기
    case pending
    //업로드 완료
    case synced
    //업로드 실패
    case failed
    //업로드 대상이 아닌 레거시 카드
    case localOnly
}
