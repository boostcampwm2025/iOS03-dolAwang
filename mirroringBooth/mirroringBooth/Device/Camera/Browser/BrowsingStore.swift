//
//  BrowsingStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import Combine
import Foundation
import UIKit

@Observable
final class BrowsingStore: StoreProtocol {

    struct State {
        var discoveredDevices: [NearbyDevice] = []
        var mirroringDevice: NearbyDevice?
        var remoteDevice: NearbyDevice?

        var isConnecting: Bool = false
        var currentTarget: DeviceUseType = .mirroring
        var hasSelectedDevice: Bool {
            switch currentTarget {
            case .mirroring: return mirroringDevice != nil
            case .remote: return remoteDevice != nil
            }
        }
        var animationTrigger: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var showTutorial: Bool = false
        var isMovingToNextStep: Bool = false
    }

    enum Intent {
        // 화면 접근
        case entry
        case exit

        // 기기 선택
        case didSelect(NearbyDevice)
        case cancel

        // 앱 상태 변화
        case didChangeAppState(UIApplication.State)

        // 기타
        case showToast(Bool, String = "")
        case showTutorial(Bool)
        case browserEvent(BrowsingEvents)
        case prepareMoveToNextStep
    }

    enum Result {
        case addDiscoveredDevice(NearbyDevice)
        case removeDiscoveredDevice(NearbyDevice)

        case setMirroringDevice(NearbyDevice?)
        case setRemoteDevice(NearbyDevice?)

        case setIsConnecting(Bool)
        case setCurrentTarget(DeviceUseType)

        case startAnimation
        case setShowToast(Bool, String)
        case setShowTutorial(Bool)

        case setIsMovingToNextStep(Bool)
    }

    private(set) var state: State = .init()
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatTask: Task<Void, Never>?

    let browser: Browser
    let watchConnectionManager: WatchConnectionManager

    var eventStream: AsyncStream<BrowsingEvents> {
        browser.browsingEventStream
    }

    init(_ browser: Browser, _ watchConnectionManager: WatchConnectionManager) {
        self.browser = browser
        self.watchConnectionManager = watchConnectionManager

        setupWatchConnectionManager()
        setupHeartbeatListener()
    }

    deinit {
        heartbeatTask?.cancel()
    }

    private func setupWatchConnectionManager() {
        browser.onRemoteModeCommand = { [weak self] in
            self?.watchConnectionManager.prepareWatchToCapture()
        }

        browser.onSelectedTimerModeCommand = { [weak self] in
            Task { @MainActor in
                // 리모트 기기가 워치인 경우 워치에게 연결 해제 알림
                if self?.state.remoteDevice?.type == .watch {
                    self?.watchConnectionManager.sendDisconnectionNotification()
                }
                self?.reduce(.setRemoteDevice(nil))
            }
        }

        watchConnectionManager.onReachableChanged = { [weak self] isReachable in
            Task { @MainActor in
                let watchDevice = NearbyDevice(
                    id: "나의 Apple Watch",
                    state: .notConnected,
                    type: .watch
                )
                if isReachable {
                    self?.reduce(.addDiscoveredDevice(watchDevice))
                } else {
                    self?.reduce(.removeDiscoveredDevice(watchDevice))
                    if self?.state.remoteDevice?.type == .watch {
                        self?.reduce(.setRemoteDevice(nil))
                    }
                }
            }
        }

        watchConnectionManager.onReceiveCaptureRequest = { [ weak self] in
            self?.browser.capturePhoto()
        }

        watchConnectionManager.onReceiveConnectionAck = { [weak self] in
            Task { @MainActor in
                let watchDevice = NearbyDevice(
                    id: "나의 Apple Watch",
                    state: .connected,
                    type: .watch
                )
                self?.reduce(.setRemoteDevice(watchDevice))
            }
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .entry:
            browser.startSearching()
            watchConnectionManager.start()
            return [.startAnimation]

        case .exit:
            browser.stopSearching()
            watchConnectionManager.stop()

            // navigation의 뒤로가기 클릭 시
            if !state.isMovingToNextStep {
                browser.disconnect()
            }

        case .didSelect(let device):
            // 1. 현재 타겟에 맞는 연결된 기기 확인
            let currentDevice: NearbyDevice? = switch state.currentTarget {
            case .mirroring:
                state.mirroringDevice
            case .remote:
                state.remoteDevice
            }

            // 2. 연결된 기기와 다른 기기를 선택했을 경우 연결 요청 전송
            if currentDevice != device {
                if device.type == .watch {
                    if state.currentTarget == .mirroring {
                        return [.setShowToast(true, "Apple Watch는 리모트 기기로만 연결할 수 있습니다.")]
                    } else {
                        watchConnectionManager.sendConnectionRequest()
                    }
                } else {
                    browser.connect(to: device.id, as: state.currentTarget)
                    return [.setIsConnecting(true)]
                }
            }

        case .cancel:
            var results: [Result] = []
            // 1. 모든 연결 해제
            browser.disconnect()

            // 워치가 연결되어 있다면 연결 해제 요청 전송
            if state.remoteDevice?.type == .watch {
                watchConnectionManager.sendDisconnectionNotification()
            }

            if state.currentTarget == .remote {
                results.append(.setCurrentTarget(.mirroring))
            }

            if let mirroringDevice = state.mirroringDevice {
                results.append(.removeDiscoveredDevice(mirroringDevice))
            }

            if let remoteDevice = state.remoteDevice {
                results.append(.removeDiscoveredDevice(remoteDevice))
            }

            // 2. 리모트 선택 중이었다면 미러링 선택 화면으로 이동
            return results + [.setMirroringDevice(nil), .setRemoteDevice(nil)]

        case .didChangeAppState(let state):
            watchConnectionManager.pushIOSAppState(state: state)

        case .showToast(let value, let message):
            return [.setShowToast(value, message)]

        case .showTutorial(let value):
            return [.setShowTutorial(value)]

        case .browserEvent(let event):
            return handleBrowserEvent(event)

        case .prepareMoveToNextStep:
            return [.setIsMovingToNextStep(true)]
        }
        return []
    }

    private func handleBrowserEvent(_ event: BrowsingEvents) -> [Result] {
        switch event {
        case .deviceConnectionFailed:
            return [.setIsConnecting(false)]
        case .deviceFound(let device):
            return [.addDiscoveredDevice(device)]
        case .deviceLost(let device):
            var results: [Result] = []
            if device == state.mirroringDevice {
                browser.disconnect(useType: .mirroring)
                results.append(contentsOf: [.setCurrentTarget(.mirroring), .setMirroringDevice(nil)])
            } else if device == state.remoteDevice {
                browser.disconnect(useType: .remote)
                results.append(.setRemoteDevice(nil))
            }
            return results + [.removeDiscoveredDevice(device)]
        case .deviceConnected(let device):
            switch state.currentTarget {
            case .mirroring:
                return [.setMirroringDevice(device), .setCurrentTarget(.remote), .setIsConnecting(false)]
            case .remote:
                return [.setRemoteDevice(device), .setIsConnecting(false)]
            }
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .addDiscoveredDevice(let device):
            // 중복 검사: id가 같은 기기가 있으면 업데이트, 없으면 추가
            if let index = state.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                state.discoveredDevices[index] = device
            } else {
                state.discoveredDevices.append(device)
            }

        case .removeDiscoveredDevice(let device):
            state.discoveredDevices.removeAll { $0.id == device.id }

        case .setMirroringDevice(let device):
            state.mirroringDevice = device
            if let id = device?.id {
                state.toastMessage = "\(id) 이/가 미러링 기기로 연결되었습니다."
                state.showToast = true
            }

        case .setRemoteDevice(let device):
            state.remoteDevice = device

        case .setIsConnecting(let isConnecting):
            state.isConnecting = isConnecting

        case .setCurrentTarget(let target):
            state.currentTarget = target

        case .startAnimation:
            state.animationTrigger = true

        case .setShowToast(let value, let message):
            state.toastMessage = message
            state.showToast = value

        case .setShowTutorial(let bool):
            state.showTutorial = bool

        case .setShowMirroringDisconnectedAlert(let bool):
            state.showMirroringDisconnectedAlert = bool

        case .setIsMovingToNextStep(let bool):
            state.isMovingToNextStep = bool
        }

        self.state = state
    }
}

extension BrowsingStore {
    private func setupHeartbeatListener() {
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            for await event in browser.browsingHeartbeatStream {
                await MainActor.run {
                    switch event {
                    case .heartbeatTimeout:
                        self.reduce(.setMirroringDevice(nil))
                        self.reduce(.setCurrentTarget(.mirroring))
                    case .remoteHeartbeatTimeout:
                        self.reduce(.setRemoteDevice(nil))
                        self.reduce(.setCurrentTarget(.remote))
                    }
                }
            }
        }
    }
}
