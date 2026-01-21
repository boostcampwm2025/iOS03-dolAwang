//
//  AdvertisingView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertisingView: View {
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) var rootStore: RootStore
    @State private var store = AdvertisingStore(
        Advertiser(
            photoCacheManager: PhotoCacheManager.shared
        )
    )

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    router.reset()
                }

            VStack(spacing: 30) {
                StandbyView(displayName: store.advertiser.myDeviceName)

                Button {
                    router.reset()
                } label: {
                    Label {
                        Text("검색 허용 중단")
                    } icon: {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    }
                    .padding(12)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .frame(maxWidth: 500, maxHeight: 800)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.background.opacity(0.6))
            }
            .padding(20)
        }
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
                    router.push(to: RemoteRoute.connected(store.advertiser))
                }
            }
        }
        .navigationBarBackButtonHidden()
        .backgroundStyle()
    }
}
