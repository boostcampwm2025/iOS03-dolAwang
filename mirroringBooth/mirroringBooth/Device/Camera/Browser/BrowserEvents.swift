//
//  Browser.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-02-02.
//

import Foundation

/// Browser에서 발생하는 모든 이벤트 타입을 정의합니다.
enum BrowserEvents {
    // 기기 발견/연결
    case deviceFound(NearbyDevice)
    case deviceLost(NearbyDevice)
    case deviceConnected(NearbyDevice)
    case deviceConnectionFailed // 마이그레이션 완료 (모든 콜백 마이그레이션 후 해당 주석은 제거될 예정입니다.)

    // 카메라
    case captureCommand
    case sendPhoto // 마이그레이션 완료

    // 리모트 모드
    case remoteModeCommand
    case selectedTimerModeCommand

    // Heartbeat
    case heartbeatTimeout
    case remoteHeartbeatTimeout
}
