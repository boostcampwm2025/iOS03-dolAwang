//
//  AdvertisingStore.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-08.
//

import Foundation

@Observable
final class AdvertisingStore: StoreProtocol {

    struct State {
        var onNavigate: Bool = false
        var deviceUseType: DeviceUseType?
        var isRemoteSelected: Bool = false
    }

    enum Intent {
        case onAppear
        case exit
    }

    enum Result {
        case setIsConnecting(Bool, type: DeviceUseType?)
        case setIsRemoteSelected(Bool)
    }

    var state: State = .init()
    let advertiser: Advertiser

    init(_ advertiser: Advertiser) {
        self.advertiser = advertiser

        advertiser.navigateToSelectModeCommandCallBack = { [weak self] isRemoteEnable in
            self?.reduce(.setIsRemoteSelected(isRemoteEnable))
            self?.reduce(.setIsConnecting(true, type: .mirroring))
        }

        advertiser.navigateToRemoteConnectedCallBack = { [weak self] in
            self?.reduce(.setIsConnecting(true, type: .remote))
        }

        advertiser.navigateToRemoteCaptureCallBack = { [weak self] in
            self?.reduce(.setIsConnecting(true, type: .remote))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            advertiser.startSearching()
            return [.setIsConnecting(false, type: nil)]

        case .exit:
            advertiser.stopSearching()
            advertiser.disconnect()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setIsConnecting(let status, let useType):
            state.onNavigate = status
            state.deviceUseType = useType

        case .setIsRemoteSelected(let isRemoteSelected):
            state.isRemoteSelected = isRemoteSelected
        }

        self.state = state
    }

}
