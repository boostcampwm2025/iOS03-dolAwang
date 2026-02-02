//
//  ConnectionCheckStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-02-02.
//

import SwiftUI

@Observable
final class ConnectionCheckStore: StoreProtocol {
    struct State {
        var remoteDevice: String?
        var isMirroringDisconnected: Bool = false
        var shouldNavigateToCompletion: Bool = false
        var showPreview: Bool = false
        var showRemoteDisconnectedAlert: Bool = false
    }

    enum Intent {
        case entry
        case onReadyToCapture
        case setNavigationToCompletion(Bool)
        case setShowPreview(Bool)
        case showRemoteDisconnectedAlert(Bool)
    }

    enum Result {
        case setRemoteDevice(String?)
        case setIsMirroringDisconnected(Bool)
        case setNavigationToCompletion(Bool)
        case setShowPreview(Bool)
        case setShowRemoteDisconnectedAlert(Bool)
    }

    private(set) var state: State = .init()

    let browser: Browser
    let cameraDevice: String
    let mirroringDevice: String

    init(
        _ list: ConnectionList,
        _ browser: Browser
    ) {
        self.cameraDevice = list.cameraName
        self.mirroringDevice = list.mirroringName
        self.browser = browser

        Task { @MainActor in
            reduce(.setRemoteDevice(list.remoteName))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .entry:
            setupBrowser()
            return []

        case .onReadyToCapture:
            browser.sendCommand(
                state.remoteDevice == nil
                ? .navigateToSelectModeWithoutRemote
                : .navigateToSelectModeWithRemote
            )
            browser.sendRemoteCommand(.navigateToRemoteConnected)
            return [.setShowPreview(true), .setNavigationToCompletion(false)]

        case .setNavigationToCompletion(let flag):
            return [.setNavigationToCompletion(flag)]

        case .setShowPreview(let flag):
            return [.setShowPreview(flag)]

        case .showRemoteDisconnectedAlert(let flag):
            return [.setShowRemoteDisconnectedAlert(flag)]
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setRemoteDevice(let name):
            state.remoteDevice = name

        case .setIsMirroringDisconnected(let flag):
            state.isMirroringDisconnected = flag

        case .setNavigationToCompletion(let flag):
            state.shouldNavigateToCompletion = flag

        case .setShowPreview(let flag):
            state.showPreview = flag

        case .setShowRemoteDisconnectedAlert(let flag):
            state.showRemoteDisconnectedAlert = flag
        }

        self.state = state
    }
}

extension ConnectionCheckStore {
    private func setupBrowser() {
        browser.onHeartbeatTimeout = { [weak self] in
            Task { @MainActor in
                self?.reduce(.setIsMirroringDisconnected(true))
            }
        }

        browser.onRemoteHeartbeatTimeout = { [weak self] in
            Task { @MainActor in
                self?.reduce(.setShowRemoteDisconnectedAlert(true))
                self?.reduce(.setRemoteDevice(nil))
            }
        }
    }
}
