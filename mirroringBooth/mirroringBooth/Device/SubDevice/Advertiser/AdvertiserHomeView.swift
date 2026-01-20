//
//  AdvertiserHomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertiserHomeView: View {
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) var rootStore: RootStore
    @State private var store = AdvertiserHomeStore(
        Advertiser(
            photoCacheManager: PhotoCacheManager.shared
        )
    )

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            MainHeaderView()
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 중앙 상태 뷰
            if store.state.isAdvertising {
                StandbyView(displayName: store.advertiser.myDeviceName, isAdvertising: store.state.isAdvertising)
            } else {
                IdleView(displayName: store.advertiser.myDeviceName)
            }

            Spacer()

            // 하단 버튼
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.send(.didTapAdvertiseButton)
                }
            } label: {
                AdvertisingButton(isAdvertising: store.state.isAdvertising)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .onAppear {
            store.send(.onAppear)
            if rootStore.advertiser == nil {
                rootStore.advertiser = store.advertiser
            }
            store.advertiser.onHeartBeatTimeout = { [weak rootStore] in
                rootStore?.send(.showTimeoutAlert(true))
            }
        }
        .onDisappear {
            store.send(.exit)
        }
        .onChange(of: store.state.hasConnectionStarted) { _, newValue in
            if newValue {
                guard let deviceUseType = store.state.deviceUseType else { return }

                switch deviceUseType {
                case .mirroring:
                    router.push(
                        to: MirroringRoute.modeSelection(
                            store.advertiser,
                            isRemoteEnable: store.state.isRemoteSelected
                        )
                    )
                case .remote:
                    router.push(to: RemoteRoute.connection(store.advertiser))
                }
            }
        }
        .backgroundStyle()
    }
}
