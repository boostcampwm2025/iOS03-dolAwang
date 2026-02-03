//
//  Browser.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-02-02.
//

import Foundation

enum BrowsingEvents {
    // 기기 발견/연결
    case deviceFound(NearbyDevice)
    case deviceLost(NearbyDevice)
    case deviceConnected(NearbyDevice)
    case deviceConnectionFailed // 마이그레이션 완료

    // 리모트 모드
    case remoteModeCommand
    case selectedTimerModeCommand

    // Heartbeat
    case heartbeatTimeout
    case remoteHeartbeatTimeout
}

enum CameraStreamEvents {
    // 촬영
    case captureCommand // 마이그레이션 완료
    case sendPhoto // 마이그레이션 완료

    // Heartbeat
    case heartbeatTimeout
    case remoteHeartbeatTimeout
}
