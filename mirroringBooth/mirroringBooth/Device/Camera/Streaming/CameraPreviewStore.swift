//
//  CameraPreviewStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/12/26.
//

import AVFoundation
import Combine
import SwiftUI

@Observable
final class CameraPreviewStore: StoreProtocol {
    struct State {
        var buffer: CMSampleBuffer?
        var deviceName: String
        var angle: Double = 0
        var transfercount: Int = -1
        var colorScheme: ColorScheme?

        var animationFlag: Bool = false
        var isTransferring: Bool = false
        var isCaptureCompleted: Bool = false
        var isPrimaryDeviceDisconnected: Bool = false
    }

    enum Intent {
        case entry(withAngle: Int)
        case exit
        case updateAngle(rawValue: Int)
        case isPrimaryDeviceDisconnected
        case browserEvent(CameraStreamEvents)
    }

    enum Result {
        case updateAngle(Int)
        case setTransferCount(Int)
        case setColorScheme(ColorScheme?)

        case startAnimation
        case setIsTransferring(Bool)
        case captureCompleted
        case resetCaptureCompleted
        case setIsPrimaryDeviceDisconnected
    }

    private(set) var state: State
    private let browser: Browser
    private let cameraManager: CameraManageable
    private let watchConnectionManager: WatchConnectionManager?
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatTask: Task<Void, Never>?

    var eventStream: AsyncStream<CameraStreamEvents> {
        browser.cameraStreamEventStream
    }

    init(
        browser: Browser,
        manager: CameraManageable,
        deviceName: String,
        watchConnectionManager: WatchConnectionManager?
    ) {
        self.browser = browser
        self.cameraManager = manager
        self.watchConnectionManager = watchConnectionManager
        self.state = State(deviceName: deviceName)

        setupHeartbeatListener()
        setupWatchConnectionListener()
    }

    deinit {
        heartbeatTask?.cancel()
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .entry(let angle):
            setupSubscriptions()
            cameraManager.startSession()
            cameraManager.rawData = { [weak self] buffer in
                guard let self = self else { return }
                self.state.buffer = buffer
            }
            return [.setColorScheme(.dark), .resetCaptureCompleted,
                    .startAnimation, .updateAngle(angle)]

        case .exit:
            cameraManager.stopSession()
            return [.setColorScheme(nil)]

        case .updateAngle(let rawValue):
            return [.updateAngle(rawValue)]

        case .isPrimaryDeviceDisconnected:
            return [.setIsPrimaryDeviceDisconnected]

        case .browserEvent(let event):
            return handleBrowserEvent(event)
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .updateAngle(let rawValue):
            state.angle = getAngleByRawValue(rawValue)

        case .setTransferCount(let count):
            state.transfercount = count

        case .setColorScheme(let scheme):
            state.colorScheme = scheme

        case .startAnimation:
            state.animationFlag = true

        case .setIsTransferring(let isTransferring):
            state.isTransferring = isTransferring

        case .captureCompleted:
            state.isCaptureCompleted = true

        case .resetCaptureCompleted:
            state.isCaptureCompleted = false

        case .setIsPrimaryDeviceDisconnected:
            state.isPrimaryDeviceDisconnected = true
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

        // 전송 완료
        cameraManager.onTransferCompleted = { [weak self] in
            Task { @MainActor in
                self?.reduce(.setIsTransferring(false))
            }
        }

        // 10장 모두 저장 완료 시 미러링기기에 알림 전송
        cameraManager.onAllPhotosStored = { [weak self] in
            Task { @MainActor in
                self?.browser.sendCommand(.onStoreAllPhotos)
                self?.watchConnectionManager?.sendCaptureComplete()
                self?.reduce(.captureCompleted)
                self?.reduce(.setTransferCount(0))
            }
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

extension CameraPreviewStore {
    private func setupHeartbeatListener() {
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            for await event in browser.cameraPreviewHeartbeatStream {
                await MainActor.run {
                    switch event {
                    case .heartbeatTimeout:
                        self.handleDisconnection()
                    case .remoteHeartbeatTimeout:
                        self.handleDisconnection()
                    }
                }
            }
        }
    }

    private func setupWatchConnectionListener() {
        watchConnectionManager?.onWatchDisconnected = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                // 타이머 모드가 선택되었으면 워치 disconnect 무시
                guard !self.browser.isTimerModeSelected else { return }
                self.handleDisconnection()
            }
        }
    }

    @MainActor
    private func handleDisconnection() {
        send(.isPrimaryDeviceDisconnected)
        browser.disconnect()
    }

    private func handleBrowserEvent(_ event: CameraStreamEvents) -> [Result] {
        switch event {
        case .sendPhoto:
            return [.setTransferCount(state.transfercount + 1)]
        case .captureCommand:
            cameraManager.capturePhoto(getOrientationByAngle(state.angle))
            return []
        case .startTransfer:
            cameraManager.sendAllPhotos(using: browser)
            return [.setIsTransferring(true)]
        }
    }
}
