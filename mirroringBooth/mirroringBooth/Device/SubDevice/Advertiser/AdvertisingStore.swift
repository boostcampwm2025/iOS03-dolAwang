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
        var isConnected: Bool = false
        var onNavigate: Bool = false
        var deviceUseType: DeviceUseType?
        var isRemoteSelected: Bool = false
    }

    enum Intent {
        case onAppear
        case connected
        case exit
    }

    enum Result {
        case setIsConnected(Bool)
        case setOnNavigate(Bool, type: DeviceUseType?)
        case setIsRemoteSelected(Bool)
    }

    var state: State = .init()
    let advertiser: Advertiser

    init(_ advertiser: Advertiser) {
        self.advertiser = advertiser

        advertiser.onConnected = { [weak self] in
            self?.send(.connected)
        }

        advertiser.navigateToSelectModeCommandCallBack = { [weak self] isRemoteEnable in
            self?.reduce(.setIsRemoteSelected(isRemoteEnable))
            self?.reduce(.setOnNavigate(true, type: .mirroring))
        }

        advertiser.navigateToRemoteConnectedCallBack = { [weak self] in
            self?.reduce(.setOnNavigate(true, type: .remote))
        }

        advertiser.navigateToRemoteCaptureCallBack = { [weak self] in
            self?.reduce(.setOnNavigate(true, type: .remote))
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            advertiser.startSearching()
            return [.setOnNavigate(false, type: nil)]

        case .connected:
            return [.setIsConnected(true)]

        case .exit:
            advertiser.stopSearching()
            advertiser.disconnect()
        }
        return []
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setIsConnected(let bool):
            state.isConnected = bool
        case .setOnNavigate(let status, let useType):
            state.onNavigate = status
            state.deviceUseType = useType

        case .setIsRemoteSelected(let isRemoteSelected):
            state.isRemoteSelected = isRemoteSelected
        }

        self.state = state
    }

}
