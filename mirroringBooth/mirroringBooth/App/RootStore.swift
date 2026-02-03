//
//  RootStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/20/26.
//

import Foundation

@Observable
final class RootStore: StoreProtocol {
    struct State {
        var showTimeoutAlert: Bool = false
    }

    enum Intent {
        case showTimeoutAlert(Bool)
        case disconnect
    }

    enum Result {
        case showTimeoutAlert(Bool)
    }

    private(set) var state: State = .init()
    private var commandTask: Task<Void, Never>?

    var advertiser: Advertiser? {
        didSet {
            commandTask?.cancel()
            setListener()
        }
    }
    var browser: Browser?

    deinit {
        commandTask?.cancel()
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .showTimeoutAlert(let bool):
            return [.showTimeoutAlert(bool)]

        case .disconnect:
            advertiser?.disconnect()
            browser?.disconnect()
            advertiser = nil
            browser = nil
        }

        return []
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .showTimeoutAlert(let bool):
            state.showTimeoutAlert = bool
        }

        self.state = state
    }
}

extension RootStore {
    private func setListener() {
        guard let advertiser else { return }
        commandTask = Task { [weak self] in
            for await stream in advertiser.rootStream {
                switch stream {
                case .onHeartbeatTimeout:
                    await MainActor.run {
                        self?.send(.showTimeoutAlert(true))
                    }
                }
            }
        }
    }
}
