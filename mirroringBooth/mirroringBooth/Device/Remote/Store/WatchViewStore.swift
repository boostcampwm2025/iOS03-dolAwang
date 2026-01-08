//
//  WatchViewStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/6/26.
//

import Foundation

@Observable
final class WatchViewStore: StoreProtocol {
    struct State {
        var connectionState: ConnectionState = .notConnected
    }

    enum Intent {
        case onAppear
        case tapRequestCapture
        case tapDisconnect
    }

    enum Result {
        case setConnectionState(ConnectionState)
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
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            self.connectionManager.start()
        case .tapRequestCapture:
            Task {
                await self.connectionManager.sendCaptureRequest()
            }
        case .tapDisconnect:
            self.connectionManager.stop()
            return [.setConnectionState(.notConnected)]
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state
        switch result {
        case .setConnectionState(let value):
            state.connectionState = value
        }
        self.state = state
    }
}
