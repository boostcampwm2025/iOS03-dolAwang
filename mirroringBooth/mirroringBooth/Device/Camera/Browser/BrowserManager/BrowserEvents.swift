//
//  BrowsingEvents.swift
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
    case deviceConnectionFailed
}

enum CameraStreamEvents {
    // 촬영
    case captureCommand
    case sendPhoto
    case startTransfer
}

enum HeartBeatEvents {
    // Heartbeat
    case heartbeatTimeout
    case remoteHeartbeatTimeout
}
