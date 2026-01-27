//
//  CameraPreviewStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/12/26.
//

import AVFoundation
import Combine
import Foundation

@Observable
final class CameraPreviewStore: StoreProtocol {
    struct State {
        var animationFlag = false
        var buffer: CMSampleBuffer?
        var deviceName: String
        var isTransferring = false
        var angle: Double = 0
        var isCaptureCompleted = false
        var showHomeAlert: Bool = false
        var isMirroringDisconnected: Bool = false
        var transfercount: Int = -1
    }

    enum Intent {
        case startAnimation
        case startSession
        case stopCameraSession
        case updateAngle(rawValue: Int)
        case captureCompleted
        case resetCaptureCompleted
        case isMirroringDisconnected
        case setTransferCount(Int)
    }

    enum Result {
        case startAnimation
        case startSession
        case updateAngle(Int)
        case captureCompleted
        case resetCaptureCompleted
        case isMirroringDisconnected
        case setTransferCount(Int)
    }

    private let browser: Browser
    private let cameraManager: CameraManager
    private(set) var state: State
    private var cancellables = Set<AnyCancellable>()

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
            setupSubscriptions()
            return [.startSession]
        case .stopCameraSession:
            cameraManager.stopSession()
        case .updateAngle(let rawValue):
            return [.updateAngle(rawValue)]
        case .captureCompleted:
            cameraManager.stopSession()
            browser.sendCommand(.allPhotosStored)
            return [.captureCompleted, .setTransferCount(0)]
        case .resetCaptureCompleted:
            return [.resetCaptureCompleted]
        case .isMirroringDisconnected:
            return [.isMirroringDisconnected]
        case .setTransferCount(let count):
            return [.setTransferCount(count)]
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
        case .updateAngle(let rawValue):
            state.angle = getAngleByRawValue(rawValue)
        case .captureCompleted:
            state.isCaptureCompleted = true
        case .resetCaptureCompleted:
            state.isCaptureCompleted = false
        case .isMirroringDisconnected:
            state.isMirroringDisconnected = true
        case .setTransferCount(let count):
            state.transfercount = count
        }

        self.state = state
    }
}

private extension CameraPreviewStore {
    func setupSubscriptions() {
        // 비디오 스트림 콜백
        cameraManager.onEncodedData = { [weak self] data in
            guard let self = self, !self.state.isTransferring else { return }

            let orientationCase = self.getOrientationByAngle(self.state.angle).rawValue

            var framedData = Data()
            framedData.append(orientationCase)
            framedData.append(data)

            self.browser.sendStreamData(framedData)
        }
        // 촬영 명령 수신
        browser.onCaptureCommand = {
            self.cameraManager.capturePhoto(
                self.getOrientationByAngle(self.state.angle)
            )
        }
        // 일괄 전송 시작 명령 수신
        browser.onStartTransferCommand
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.state.isTransferring = true
                self.cameraManager.sendAllPhotos(using: self.browser)
            }
            .store(in: &cancellables)
        // 장당 전송 완료
        browser.onSendPhoto = { [weak self] in
            guard let self else { return }
            self.send(.setTransferCount(self.state.transfercount + 1))
        }

        // 전송 완료
        cameraManager.onTransferCompleted = {
            self.state.isTransferring = false
        }
        // 10장 모두 저장 완료 시 미러링기기에 알림 전송
        cameraManager.onAllPhotosStored = { _ in
            self.send(.captureCompleted)
        }
    }

    func getAngleByRawValue(_ value: Int) -> Double {
        switch value {
        case 3: return 90   // landscapeLeft
        case 4: return -90  // landscapeRight
        case 5: return state.angle    // flat
        default: return 0
        }
    }

    func getOrientationByAngle(_ angle: Double) -> CameraOrientation {
        switch angle {
        case -90: return .landscapeLeft
        case 90: return .landscapeRight
        default: return .portrait
        }
    }
}
