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
    case navigateToSelectModeCommandCallBack(_ isRemoteEnable: Bool)
    /// 촬영 대기 화면 이동 (리모트 기기)
    case navigateToRemoteConnectedCallBack
}

enum FrameReceivingEvents {
    case streamDataReceived(Data)
}
