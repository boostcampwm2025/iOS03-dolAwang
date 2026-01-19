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
    }

    enum Intent {
        case onAppear
        case didTapAdvertiseButton
        case exit
    }

    enum Result {
        case setIsAdvertising(Bool)
        case setIsConnecting(Bool)
    }

    var state: State = .init()
    let advertiser: Advertiser

    init(_ advertiser: Advertiser) {
        self.advertiser = advertiser

        advertiser.navigateToSelectModeCommandCallBack = { [weak self] in
            self?.reduce(.setIsConnecting(true))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            return [.setIsAdvertising(false), .setIsConnecting(false)]
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
        }

        self.state = state
    }

}
