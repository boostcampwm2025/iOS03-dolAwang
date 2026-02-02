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
        case setShowPreview(Bool)
        case setNavigationToCompletion(Bool)
        case setShowRemoteDisconnectedAlert(Bool)
        case onReadyToCapture
    }

    enum Result {
        case setRemoteDevice(String?)
        case setShowPreview(Bool)
        case setNavigationToCompletion(Bool)
        case setIsMirroringDisconnected(Bool)
        case setShowRemoteDisconnectedAlert(Bool)
    }

    private(set) var state: State = .init()

    let cameraDevice: String
    let mirroringDevice: String
    let browser: Browser

    init(
        _ list: ConnectionList,
        _ browser: Browser
    ) {
        self.cameraDevice = list.cameraName
        self.mirroringDevice = list.mirroringName
        self.browser = browser

        reduce(.setRemoteDevice(list.remoteName))
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .entry:
            setupBrowser()
            return []

        case .setShowPreview(let flag):
            return [.setShowPreview(flag)]

        case .setNavigationToCompletion(let flag):
            return [.setNavigationToCompletion(flag)]

        case .setShowRemoteDisconnectedAlert(let flag):
            return [.setShowRemoteDisconnectedAlert(flag)]

        case .onReadyToCapture:
            browser.sendCommand(
                state.remoteDevice == nil
                ? .navigateToSelectModeWithoutRemote
                : .navigateToSelectModeWithRemote
            )
            browser.sendRemoteCommand(.navigateToRemoteConnected)
            return [.setShowPreview(true), .setNavigationToCompletion(false)]
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setRemoteDevice(let name):
            state.remoteDevice = name

        case .setShowPreview(let flag):
            state.showPreview = flag

        case .setNavigationToCompletion(let flag):
            state.shouldNavigateToCompletion = flag

        case .setIsMirroringDisconnected(let flag):
            state.isMirroringDisconnected = flag

        case .setShowRemoteDisconnectedAlert(let flag):
            state.showRemoteDisconnectedAlert = flag
        }

        self.state = state
    }
}

extension ConnectionCheckStore {
    private func setupBrowser() {
        browser.onRemoteHeartbeatTimeout = { [weak self] in
            self?.reduce(.setIsMirroringDisconnected(true))
        }

        browser.onRemoteHeartbeatTimeout = { [weak self] in
            self?.reduce(.setShowRemoteDisconnectedAlert(true))
            self?.reduce(.setRemoteDevice(nil))
        }
    }
}
