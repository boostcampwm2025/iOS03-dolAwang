//
//  BrowsingStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import Foundation
import UIKit

@Observable
final class BrowsingStore: StoreProtocol {

    struct State {
        var currentTarget: DeviceUseType = .mirroring
        var discoveredDevices: [NearbyDevice] = []
        var mirroringDevice: NearbyDevice?
        var remoteDevice: NearbyDevice?

        var isConnecting: Bool = false
        var hasSelectedDevice: Bool {
            switch currentTarget {
            case .mirroring: return mirroringDevice != nil
            case .remote: return remoteDevice != nil
            }
        }
        var animationTrigger = false
    }

    enum Intent {
        case entry
        case exit
        case didSelect(NearbyDevice)
        case cancel
        case didChangeAppState(UIApplication.State)
    }

    enum Result {
        case addDiscoveredDevice(NearbyDevice)
        case removeDiscoveredDevice(NearbyDevice)
        case setMirroringDevice(NearbyDevice?)
        case setRemoteDevice(NearbyDevice?)
        case setIsConnecting(Bool)
        case setCurrentTarget(DeviceUseType)
        case startAnimation
    }

    var state: State = .init()
    let browser: Browser
    let watchConnectionManager: WatchConnectionManager

    init(_ browser: Browser, _ watchConnectionManager: WatchConnectionManager) {
        self.browser = browser
        self.watchConnectionManager = watchConnectionManager

        setupBrowser()
        setupWatchConnectionManager()
    }

    private func setupBrowser() {
        browser.onDeviceFound = { [weak self] device in
            self?.reduce(.addDiscoveredDevice(device))
        }

        browser.onDeviceLost = { [weak self] device in
            self?.reduce(.removeDiscoveredDevice(device))
        }

        browser.onDeviceConnected = { [weak self] device in
            switch self?.state.currentTarget {
            case .mirroring:
                self?.reduce(.setMirroringDevice(device))
                self?.reduce(.setCurrentTarget(.remote))
            case .remote:
                self?.reduce(.setRemoteDevice(device))
            case .none:
                break
            }
            self?.reduce(.setIsConnecting(false))
        }

        browser.onDeviceConnectionFailed = { [weak self] in
            self?.reduce(.setIsConnecting(false))
        }

        browser.onRemoteModeCommand = { [weak self] in
            self?.watchConnectionManager.prepareWatchToCapture()
        }
    }

    private func setupWatchConnectionManager() {
        watchConnectionManager.onReachableChanged = { [weak self] isReachable in
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

        watchConnectionManager.onReceiveCaptureRequest = { [ weak self] in
            self?.browser.capturePhoto()
        }

        watchConnectionManager.onReceiveConnectionAck = { [weak self] in
            let watchDevice = NearbyDevice(
                id: "나의 Apple Watch",
                state: .connected,
                type: .watch
            )
            self?.reduce(.setRemoteDevice(watchDevice))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        var result: [Result] = []

        switch intent {
        case .entry:
            browser.startSearching()
            watchConnectionManager.start()
            return [.startAnimation]
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
                    result.append(.setIsConnecting(true))
                }
            }

        case .cancel:
            // 1. 모든 연결 해제
            browser.disconnect()

            // 워치가 연결되어 있다면 연결 해제 요청 전송
            if state.remoteDevice?.type == .watch {
                watchConnectionManager.sendDisconnectRequest()
            }

            result.append(.setMirroringDevice(nil))
            result.append(.setRemoteDevice(nil))

            // 2. 리모트 선택 중이었다면 미러링 선택 화면으로 이동
            if state.currentTarget == .remote {
                result.append(.setCurrentTarget(.mirroring))
            }

        case .didChangeAppState(let state):
            watchConnectionManager.pushIOSAppState(state: state)
        }

        return result
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

        case .setRemoteDevice(let device):
            state.remoteDevice = device

        case .setIsConnecting(let isConnecting):
            state.isConnecting = isConnecting

        case .setCurrentTarget(let target):
            state.currentTarget = target
        case .startAnimation:
            state.animationTrigger = true
        }

        self.state = state
    }

}
