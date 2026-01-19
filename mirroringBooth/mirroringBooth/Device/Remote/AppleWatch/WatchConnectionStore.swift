//
//  WatchConnectionStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/6/26.
//

import Foundation

@Observable
final class WatchConnectionStore: StoreProtocol {
    struct State {
        var connectionState: ConnectionState = .notConnected
        var isReadyToCapture: Bool = false
        var isCaptureCompleted: Bool = false
    }

    enum Intent {
        case tapRequestCapture
        case startConnecting
        case disconnect
    }

    enum Result {
        case setConnectionState(ConnectionState)
        case setIsReadyToCapture(Bool)
    }

    private let connectionManager: WatchConnectionManager
    private(set) var state: State = .init()

    init(
        connectionManager: WatchConnectionManager
    ) {
        self.connectionManager = connectionManager

        self.connectionManager.onReachableChanged = { [weak self] reachable in
            guard let self = self else { return }
            let connectivity: ConnectionState = reachable ? .connected : .notConnected
            self.reduce(.setConnectionState(connectivity))
        }

        self.connectionManager.onReceiveConnectionCompleted = { [weak self] in
            self?.reduce(.setConnectionState(.connected))
        }

        self.connectionManager.onReceiveRequestToPrepare = { [weak self] in
            self?.reduce(.setIsReadyToCapture(true))
        }

        self.connectionManager.onReceiveCaptureComplete = { [weak self] in
            self?.state.isCaptureCompleted = true
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .tapRequestCapture:
            Task {
                await self.connectionManager.sendCaptureRequest()
            }
        case .disconnect:
            self.connectionManager.stop()
            return [.setConnectionState(.notConnected)]
        case .startConnecting:
            self.connectionManager.start()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state
        switch result {
        case .setConnectionState(let value):
            state.connectionState = value

        case .setIsReadyToCapture(let value):
            state.isReadyToCapture = value
        }
        self.state = state
    }
}
