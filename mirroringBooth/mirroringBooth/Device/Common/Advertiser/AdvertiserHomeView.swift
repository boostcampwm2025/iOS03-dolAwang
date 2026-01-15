//
//  AdvertiserHomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertiserHomeView: View {
    @Environment(Router.self) var router: Router
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
        .onDisappear {
            store.send(.exit)
        }
        .onChange(of: store.state.hasConnectionStarted) { _, newValue in
            if newValue {
                guard let deviceUseType = store.state.deviceUseType else { return }

                switch deviceUseType {
                case .mirroring:
                    router.push(to: MirroringRoute.modeSelection(store.advertiser))
                case .remote:
                    router.push(to: RemoteRoute.connectionTest(store.advertiser))
                }
            }
        }
    }
}
