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
        var showTutorial: Bool = false
    }

    enum Intent {
        case onAppear
        case connected
        case exit
        case setShowTutorial(Bool)
    }

    enum Result {
        case setIsConnected(Bool)
        case setOnNavigate(Bool, type: DeviceUseType?)
        case setIsRemoteSelected(Bool)
        case setShowTutorial(Bool)
    }

    var state: State = .init()
    let advertiser: Advertiser
    private var commandTask: Task<Void, Never>?

    init(_ advertiser: Advertiser) {
        self.advertiser = advertiser
        subscribeToStream()
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            advertiser.startSearching()
            return [.setOnNavigate(false, type: nil)]

        case .connected:
            advertiser.stopSearching(onlyRefuse: true)
            return [.setIsConnected(true)]

        case .exit:
            commandTask?.cancel()
            advertiser.stopSearching()
            return []

        case .setShowTutorial(let value):
            return [.setShowTutorial(value)]
        }
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

        case .setShowTutorial(let bool):
            state.showTutorial = bool
        }

        self.state = state
    }

}

// MARK: Stream 구독
extension AdvertisingStore {
    private func subscribeToStream() {
        commandTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await stream in advertiser.advertisingStream {
                switch stream {
                case .onConnected:
                    self.send(.connected)
                case .navigateToSelectModeCommand(let isRemoteEnable):
                    self.reduce(.setIsRemoteSelected(isRemoteEnable))
                    self.reduce(.setOnNavigate(true, type: .mirroring))
                case .navigateToRemoteConnected:
                    self.reduce(.setOnNavigate(true, type: .remote))
                case .navigateToRemoteCapture:
                    self.reduce(.setOnNavigate(true, type: .remote))
                }
            }
        }
    }
}
