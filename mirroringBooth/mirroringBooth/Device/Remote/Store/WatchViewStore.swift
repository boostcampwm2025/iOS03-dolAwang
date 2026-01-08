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
        var isReadyToCapture: Bool = false
        var isConnecting: Bool = false
    }

    enum Intent {
        case tapRequestCapture
        case tapDisconnect // TODO: 연결 끊기 버튼 추가 후 View에서 호출
        case tapConnect
        case startConnecting
    }

    enum Result {
        case setConnectionState(ConnectionState)
        case setIsReadyToCapture(Bool)
        case setIsConnecting(Bool)
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
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .tapRequestCapture:
            Task {
                await self.connectionManager.sendCaptureRequest()
            }
        case .tapDisconnect:
            self.connectionManager.stop()
            return [.setIsConnecting(false), .setConnectionState(.notConnected)]
        case .tapConnect:
            return [.setIsConnecting(true)]
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

        case .setIsConnecting(let value):
            state.isConnecting = value
        }
        self.state = state
    }
}
