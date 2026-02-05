//
//  ModeSelectionStore.swift
//  mirroringBooth
//
//  Created by 최윤진 on 2/4/26.
//

import OSLog

@Observable
final class ModeSelectionStore: StoreProtocol {
    struct State {
        var showHomeAlert: Bool = false
    }

    enum Intent {
        case showHomeAlert(Bool)
        case timerMode, remoteMode
    }

    enum Result {
        case setShowHomeAlert(Bool)
    }

    private(set) var state: State = .init()
    let selectionType: ModeSelectionType
    /// 촬영 모드 선택 때는 '리모트 가능 여부 ' / 포즈 추천 여부 선택 때는 '현재 타이머 모드인지 여부'
    let flag: Bool
    let advertiser: Advertiser?

    init(
        type: ModeSelectionType,
        flag: Bool,
        advertiser: Advertiser? = nil
    ) {
        self.selectionType = type
        self.flag = flag
        self.advertiser = advertiser

        if type == .poseSuggestion && advertiser == nil {
            Logger.modeSelectionView.error("포즈 추천 여부 선택 상황이지만, advertiser가 없어 정상 동작하지 않습니다.")
        }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .showHomeAlert(let show):
            return [.setShowHomeAlert(show)]

        case .remoteMode:
            if let advertiser, !flag {
                advertiser.sendCommand(.setRemoteMode)
            }
        case .timerMode:
            if let advertiser {
                advertiser.sendCommand(.selectedTimerMode)
            }
        }

        return []
    }

    func reduce(_ result: Result) {
        switch result {
        case .setShowHomeAlert(let value):
            state.showHomeAlert = value
        }
    }
}
