//
//  ModeSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/6/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) private var rootStore
    @State private var store: ModeSelectionStore

    init(
        for type: ModeSelectionType,
        flag: Bool,
        advertiser: Advertiser? = nil
    ) {
        self.store = .init(
            type: type,
            flag: flag,
            advertiser: advertiser
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            DisconnectButtonView {
                store.send(.showHomeAlert(true))
            }

            titleView

            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    HStack(spacing: 40) {
                        firstCard
                        secondCard
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                } else {
                    VStack(spacing: 20) {
                        firstCard
                        secondCard

                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                }

            }

            Spacer()
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .navigationBarBackButtonHidden()
        .backgroundStyle()
        .homeAlert(isPresented: Binding(
            get: { store.state.showHomeAlert },
            set: { store.send(.showHomeAlert($0)) }
        )) {
            router.reset()
            rootStore.send(.disconnect)
        }
    }

    @ViewBuilder
    private var firstCard: some View {
        switch store.selectionType {
        case .timerOrRemote:
            SelectionCard(
                iconName: "stopwatch",
                iconColor: Color.main,
                title: "타이머 모드",
                description: "80초 동안 8초 간격으로\n자동 촬영합니다."
            ) {
                store.send(.chooseMode(.timer))
                router.push(to: MirroringRoute.poseSuggestionSelection(isTimerMode: true))
            }

        case .poseSuggestion:
            SelectionCard(
                iconName: "face.smiling",
                iconColor: Color.pink,
                title: "포즈 추천 받을래요",
                description: "포즈를 정하기 어려우신가요?\n이모지를 통해 포즈를 추천해 드릴게요!"
            ) {
                store.send(.chooseMode(.remote))
                router.push(to: MirroringRoute.streaming(isTimerMode: store.flag, isPoseSuggestionEnabled: true))
            }
        }
    }

    @ViewBuilder
    private var secondCard: some View {
        switch store.selectionType {
        case .timerOrRemote:
            SelectionCard(
                iconName: "target", // SF Symbol
                iconColor: Color.remote,
                title: "리모콘 모드",
                description: "나의 Apple Watch에서 \n직접 셔터를 누르세요."
            ) {
                noticeShootingMode(isTimer: false)
                router.push(to: MirroringRoute.poseSuggestionSelection(isTimerMode: false))
            }
            .disabled(!store.flag)

        case .poseSuggestion:
            SelectionCard(
                iconName: "face.dashed",
                iconColor: Color.black,
                title: "추천은 괜찮아요",
                description: "자유롭게 촬영을 진행해보세요!"
            ) {
                store.send(.chooseMode(.remote))
                router.push(to: MirroringRoute.streaming(isTimerMode: store.flag, isPoseSuggestionEnabled: false))
            }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        VStack(spacing: 12) {
            let title: String = {
                switch store.selectionType {
                case .timerOrRemote:
                    return "촬영 방식 선택"
                case .poseSuggestion:
                    return "포즈 추천 받기"
                }
            }()

            Text(title)
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("어떻게 촬영하시겠어요?")
                .font(.callout)
                .foregroundColor(.gray)
        }
    }
}
