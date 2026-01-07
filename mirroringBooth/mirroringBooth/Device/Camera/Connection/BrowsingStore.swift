//
//  BrowsingStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import Foundation

@Observable
final class BrowsingStore: StoreProtocol {

    struct State {
        var currentTarget: ConnectionTargetType = .mirroring
        var discoveredDevices: [NearbyDevice] = []
        var mirroringDevice: NearbyDevice?
        var remoteDevice: NearbyDevice?
        var isConnecting: Bool = false
    }

    enum Intent {
        case entry
        case didSelect(NearbyDevice)
        case cancel
    }

    enum Result {
        case addDiscoveredDevice(NearbyDevice)
        case removeDiscoveredDevice(NearbyDevice)
        case setMirroringDevice(NearbyDevice?)
        case setRemoteDevice(NearbyDevice?)
        case setIsConnecting(Bool)
        case setCurrentTarget(ConnectionTargetType)
    }

    var state: State = .init()
    let browser: Browser

    init(_ browser: Browser) {
        self.browser = browser

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
            case .remote:
                self?.reduce(.setRemoteDevice(device))
            case .none:
                break
            }
            self?.reduce(.setIsConnecting(false))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        var result: [Result] = []

        switch intent {
        case .entry:
            browser.startSearching()

        case .didSelect(let device):
            // 1. 현재 연결된 기기 확인
            var current: NearbyDevice?
            switch state.currentTarget {
            case .mirroring:
                current = state.mirroringDevice
            case .remote:
                current = state.remoteDevice
            }

            // 2. 연결된 기기와 다른 기기를 선택했을 경우 연결 요청
            if current != device {
                browser.connect(to: device.id)
                result.append(.setMirroringDevice(device))
                result.append(.setIsConnecting(true))
            }

        case .cancel:
            // 1. 모든 연결 해제
            browser.disconnect()
            result.append(.setMirroringDevice(nil))
            result.append(.setRemoteDevice(nil))

            // 2. 리모트 선택 중이었다면 미러링 선택 화면으로 이동
            if state.currentTarget == .remote {
                result.append(.setCurrentTarget(.mirroring))
            }
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
        }

        self.state = state
    }

}
