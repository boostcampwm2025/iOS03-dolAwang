//
//  CameraPreviewStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/12/26.
//

import AVFoundation
import Foundation

@Observable
final class CameraPreviewStore: StoreProtocol {
    struct State {
        var animationFlag = false
        var buffer: CMSampleBuffer?
        var deviceName: String
        var isTransferring = false
    }

    enum Intent {
        case startAnimation
        case startSession
        case tapExitButton
    }

    enum Result {
        case startAnimation
        case startSession
    }

    private let browser: Browser
    private let cameraManager: CameraManager
    private(set) var state: State

    init(
        browser: Browser,
        manager: CameraManager,
        deviceName: String,
    ) {
        self.browser = browser
        self.cameraManager = manager
        self.state = State(deviceName: deviceName)
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .startAnimation:
            return [.startAnimation]
        case .startSession:
            setupCallbacks()
            return [.startSession]
        case .tapExitButton:
            cameraManager.stopSession()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state
        switch result {
        case .startAnimation:
            state.animationFlag = true
        case .startSession:
            cameraManager.startSession()
            cameraManager.rawData = { buffer in
                self.state.buffer = buffer
            }
        }
        self.state = state
    }
}

private extension CameraPreviewStore {
    func setupCallbacks() {
        // 비디오 스트림 콜백
        cameraManager.onEncodedData = { data in
            guard !self.state.isTransferring else { return }
            self.browser.sendStreamData(data)
        }
        // 촬영 명령 수신
        browser.onCaptureCommand = {
            self.cameraManager.capturePhoto()
        }
        // 일괄 전송 시작 명령 수신
        browser.onStartTransferCommand = {
            self.state.isTransferring = true
            self.cameraManager.sendAllPhotos(using: self.browser)
        }
        // 전송 완료
        cameraManager.onTransferCompleted = {
            self.state.isTransferring = false
        }
        // 10장 모두 저장 완료 시 iPad에 알림 전송
        cameraManager.onAllPhotosStored = { _ in
            self.browser.sendCommand(.allPhotosStored)
        }
    }
}
