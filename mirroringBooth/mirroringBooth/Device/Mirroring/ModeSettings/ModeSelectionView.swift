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
    private let selectionType: ModeSelectionType
    private let advertiser: Advertiser
    private let isRemoteModeEnabled: Bool

    @State private var showHomeAlert: Bool = false

    init(for type: ModeSelectionType, advertiser: Advertiser, isRemoteModeEnabled: Bool) {
        self.selectionType = type
        self.advertiser = advertiser
        self.isRemoteModeEnabled = isRemoteModeEnabled
    }

    var body: some View {
        VStack(spacing: 20) {
            DisconnectButtonView {
                showHomeAlert = true
            }

            titleView

            GeometryReader { proxy in
                if proxy.size.width > proxy.size.height {
                    HStack(spacing: 40) {
                        timerCard
                        remoteCard
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                } else {
                    VStack(spacing: 20) {
                        timerCard
                        remoteCard

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
        .homeAlert(isPresented: $showHomeAlert) {
            router.reset()
            rootStore.send(.disconnect)
        }
    }

    @ViewBuilder
    private var timerCard: some View {
        switch selectionType {
        case .timerOrRemote:
            SelectionCard(
                iconName: "stopwatch",
                iconColor: Color.main,
                title: "타이머 모드",
                description: "80초 동안 8초 간격으로\n자동 촬영합니다."
            ) {
                advertiser.sendCommand(.selectedTimerMode)
                router.push(to: MirroringRoute.streaming(advertiser, isTimerMode: true))
            }

        case .poseSuggestion:
            SelectionCard(
                iconName: "face.smiling",
                iconColor: Color.pink,
                title: "포즈 추천 받을래요",
                description: "포즈를 정하기 어려우신가요?\n이모지를 통해 포즈를 추천해 드릴게요!"
            ) { }
        }
    }

    @ViewBuilder
    private var remoteCard: some View {
        switch selectionType {
        case .timerOrRemote:
            SelectionCard(
                iconName: "target", // SF Symbol
                iconColor: Color.remote,
                title: "리모콘 모드",
                description: "나의 Apple Watch에서 \n직접 셔터를 누르세요."
            ) {
                advertiser.sendCommand(.setRemoteMode)
                router.push(to: MirroringRoute.streaming(advertiser, isTimerMode: false))
            }
            .disabled(!isRemoteModeEnabled)

        case .poseSuggestion:
            SelectionCard(
                iconName: "face.dashed",
                iconColor: Color.black,
                title: "추천은 괜찮아요",
                description: "자유롭게 촬영을 진행해보세요!"
            ) { }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        VStack(spacing: 12) {
            let title: String = {
                switch selectionType {
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
