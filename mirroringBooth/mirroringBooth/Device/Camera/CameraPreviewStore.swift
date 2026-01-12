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

    private let manager: CameraManager
    private(set) var state: State

    init(manager: CameraManager, deviceName: String) {
        self.manager = manager
        self.state = State(deviceName: deviceName)
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .startAnimation:
            return [.startAnimation]
        case .startSession:
            return [.startSession]
        case .tapExitButton:
            manager.stopSession()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state
        switch result {
        case .startAnimation:
            state.animationFlag = true
        case .startSession:
            manager.startSession()
            manager.rawData = { buffer in
                self.state.buffer = buffer
            }
        }
        self.state = state
    }
}
