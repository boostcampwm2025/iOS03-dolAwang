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

    var state: State = .init()
    var advertiser: Advertiser?
    var browser: Browser?

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case let .showTimeoutAlert(bool):
            return [.showTimeoutAlert(bool)]
        case .disconnect:
            advertiser?.disconnect()
            browser?.disconnect()
            return []
        }
    }

    func reduce(_ result: Result) {
        switch result {
        case let .showTimeoutAlert(bool):
            state.showTimeoutAlert = bool
        }
    }
}
