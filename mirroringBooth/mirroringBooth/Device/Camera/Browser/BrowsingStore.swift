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

        var currentTarget: DeviceUseType = .mirroring
        var isConnecting: Bool = false
        var hasSelectedDevice: Bool {
            switch currentTarget {
            case .mirroring: return mirroringDevice != nil
            case .remote: return remoteDevice != nil
            }
        }
        var animationTrigger: Bool = false
        var showMirroringDisconnectedAlert: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var showTutorial: Bool = false
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
        case showMirroringDisconnectedAlert(Bool)
        case showToast(Bool)
        case showTutorial(Bool)
        case browserEvent(BrowsingEvents)
    }

    enum Result {
        case addDiscoveredDevice(NearbyDevice)
        case removeDiscoveredDevice(NearbyDevice)

        case setMirroringDevice(NearbyDevice?)
        case setRemoteDevice(NearbyDevice?)

        case setIsConnecting(Bool)
        case setCurrentTarget(DeviceUseType)

        case startAnimation
        case setShowMirroringDisconnectedAlert(Bool)
        case setShowToast(Bool)
        case setShowTutorial(Bool)
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

        setupBrowser()
        setupWatchConnectionManager()
        setupHeartbeatListener()
    }

    deinit {
        heartbeatTask?.cancel()
    }

    private func setupBrowser() {
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
    }

    private func setupWatchConnectionManager() {
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
            return [.startAnimation] + clearDevices()

        case .exit:
            browser.stopSearching()
            watchConnectionManager.stop()

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
                    watchConnectionManager.sendConnectionRequest()
                } else {
                    browser.connect(to: device.id, as: state.currentTarget)
                    return [.setIsConnecting(true)]
                }
            }

        case .cancel:
            // 1. 모든 연결 해제
            browser.disconnect()

            // 워치가 연결되어 있다면 연결 해제 요청 전송
            if state.remoteDevice?.type == .watch {
                watchConnectionManager.sendDisconnectionNotification()
            }

            return [.setMirroringDevice(nil), .setRemoteDevice(nil)]
                       + (state.currentTarget == .remote ? [.setCurrentTarget(.mirroring)] : [])

        case .didChangeAppState(let state):
            watchConnectionManager.pushIOSAppState(state: state)

        case .showMirroringDisconnectedAlert(let value):
            return [.setShowMirroringDisconnectedAlert(value)]

        case .showToast(let value):
            return [.setShowToast(value)]

        case .showTutorial(let value):
            return [.setShowTutorial(value)]

        case .browserEvent(let event):
            return handleBrowserEvent(event)
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
            if device == state.mirroringDevice {
                return [.removeDiscoveredDevice(device), .setCurrentTarget(.mirroring)]
            }
            return [.removeDiscoveredDevice(device)]

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
            if self.state.currentTarget == .remote, target == .mirroring {
                state.showMirroringDisconnectedAlert = true
            }

        case .startAnimation:
            state.animationTrigger = true

        case .setShowMirroringDisconnectedAlert(let alert):
            state.showMirroringDisconnectedAlert = alert

        case .setShowToast(let value):
            state.showToast = value

        case .setShowTutorial(let bool):
            state.showTutorial = bool
        }

        self.state = state
    }
}

extension BrowsingStore {
    func clearDevices() -> [Result] {
        var results: [Result] = []
        if !browser.isMirroringSessionActive {
            if let mirroringDevice = state.mirroringDevice {
                results.append(.setMirroringDevice(nil))
                results.append(.removeDiscoveredDevice(mirroringDevice))
            }
            results.append(.setCurrentTarget(.mirroring))
        } else if !browser.isRemoteSessionActive {
            if let remoteDevice = state.remoteDevice {
                results.append(.setRemoteDevice(nil))
                results.append(.removeDiscoveredDevice(remoteDevice))
            }
            results.append(.setCurrentTarget(.remote))
        }
        return results
    }

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
