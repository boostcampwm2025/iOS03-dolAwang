//
//  AdvertiserEvents.swift
//  mirroringBooth
//
//  Created by Liam on 2/2/26.
//

import Foundation

enum AdvertiserEvents {
    /// 연결 성공
    case onConnected
    /// 미러링 화면 모드 선택으로 이동(리모트 기기 연결 여부)
    case navigateToSelectModeCommand(_ isRemoteEnable: Bool)
    /// 촬영 대기 화면 이동 (리모트 기기)
    case navigateToRemoteConnected
    case navigateToRemoteCapture
}

enum ModeSelectionEvents {
    /// 리모트 기기 연결 끊겼을 때 모드 선택 화면 교체
    case switchModeSelectionView
}

enum RemoteConnectedViewEvents {
    /// 촬영 화면 이동 콜백 (리모트 기기)
    case navigateToRemoteCapture
    /// 홈 화면으로 이동 (리모트 기기)
    case navigateToHome
}

enum RemoteCaptureViewEvents {
    case navigateToRemoteComplete
}

enum FrameReceivingEvents {
    case streamDataReceived(Data)
}
