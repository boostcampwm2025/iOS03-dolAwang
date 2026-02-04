//
//  BrowserCommands.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2/4/26.
//

enum MirroringDeviceCommand: String {
    case navigateToSelectModeWithRemote
    case navigateToSelectModeWithoutRemote
    case switchSelectModeView
    case onStoreAllPhotos // 사진 10장 저장 시작 명령(from camera)
    case onUpdateCaptureCount // 리모트 기기에서 카메라 캡처 요청 보내기
    case heartBeat
    case captureEffect
}

enum RemoteDeviceCommand: String {
    case navigateToRemoteCapture
    case navigateToRemoteComplete
    case navigateToRemoteConnected
    case navigateToHome
    case noticeIsRemoteDevice
    case heartBeat
    case stopHeartBeat
}
