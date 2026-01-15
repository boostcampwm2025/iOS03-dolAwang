//
//  AdvertiserHomeStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-08.
//

import Foundation

@Observable
final class AdvertiserHomeStore: StoreProtocol {

    struct State {
        var isAdvertising: Bool = false
        var hasConnectionStarted: Bool = false
        var isReconnectRequired: Bool = false
    }

    enum Intent {
        case didTapAdvertiseButton
        case exit
    }

    enum Result {
        case setIsAdvertising(Bool)
        case setIsConnecting(Bool)
        case setIsReconnectRequired(Bool)
    }

    var state: State = .init()
    let advertiser: Advertiser

    init(_ advertiser: Advertiser) {
        self.advertiser = advertiser

        advertiser.navigateToSelectModeCommandCallBack = { [weak self] in
            self?.reduce(.setIsConnecting(true))
        }

        advertiser.onDisconnected = { [weak self] in
            self?.reduce(.setIsReconnectRequired(true))
        }

        advertiser.onReconnected = { [weak self] in
            self?.reduce(.setIsReconnectRequired(false))
        }
    }

    deinit {
        advertiser.disconnect()
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .didTapAdvertiseButton:
            let newState = !state.isAdvertising
            if newState {
                advertiser.startSearching()
            } else {
                advertiser.stopSearching()
            }
            return [.setIsAdvertising(newState)]

        case .exit:
            advertiser.stopSearching()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setIsAdvertising(let status):
            state.isAdvertising = status

        case .setIsConnecting(let status):
            state.hasConnectionStarted = status

        case .setIsReconnectRequired(let status):
            state.isReconnectRequired = status
        }

        self.state = state
    }

}
