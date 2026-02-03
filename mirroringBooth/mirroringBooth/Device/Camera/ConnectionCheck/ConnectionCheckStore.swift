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
        case setShowRemoteDisconnectedAlert(Bool)
        case setShowPreview(Bool)
    }

    enum Result {
        case setRemoteDevice(String?)
        case setIsMirroringDisconnected(Bool)
        case setNavigationToCompletion(Bool)
        case setShowRemoteDisconnectedAlert(Bool)
        case setShowPreview(Bool)
    }

    private(set) var state: State = .init()

    let browser: Browser
    let cameraDevice: String
    let mirroringDevice: String

    private var heartbeatTask: Task<Void, Never>?

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

    deinit {
        heartbeatTask?.cancel()
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .entry:
            setupHeartbeatListener()
            
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
            
        case .setShowRemoteDisconnectedAlert(let flag):
            return [.setShowRemoteDisconnectedAlert(flag)]
            
        case .setShowPreview(let flag):
            return [.setShowPreview(flag)]
        }

        return []
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

        case .setShowRemoteDisconnectedAlert(let flag):
            state.showRemoteDisconnectedAlert = flag

        case .setShowPreview(let flag):
            state.showPreview = flag
        }

        self.state = state
    }
}

extension ConnectionCheckStore {
    private func setupHeartbeatListener() {
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            for await event in browser.connectionCheckHeartbeatStream {
                await MainActor.run {
                    switch event {
                    case .heartbeatTimeout:
                        self.reduce(.setIsMirroringDisconnected(true))
                    case .remoteHeartbeatTimeout:
                        self.reduce(.setShowRemoteDisconnectedAlert(true))
                        self.reduce(.setRemoteDevice(nil))
                    }
                }
            }
        }
    }
}
