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
                if store.state.isConnected {
                    ConnectedView(description: "촬영 대기 중입니다.")
                } else {
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
            }
            .frame(maxWidth: 500, maxHeight: 700)
            .aspectRatio(5/7, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.background.opacity(store.state.isConnected ? 1.0 : 0.6))
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
        .onChange(of: store.state.onNavigate) { _, newValue in
            if newValue {
                guard let deviceUseType = store.state.deviceUseType else { return }

                switch deviceUseType {
                case .mirroring:
                    router.push(
                        to: MirroringRoute.timerOrRemoteSelection(isRemoteEnable: store.state.isRemoteSelected)
                    )
                case .remote:
                    // 리모트 모드 선택 시 촬영 뷰로 이동
                    store.advertiser.navigateToRemoteCaptureCallBack = { [weak router] in
                        guard let router else { return }
                        DispatchQueue.main.async {
                            router.push(to: RemoteRoute.remoteCapture(store.advertiser))
                        }
                    }

                    // 타이머 모드 선택 시 처음 화면으로 이동
                    store.advertiser.navigateToHomeCallback = { [weak router] in
                        guard let router else { return }
                        DispatchQueue.main.async {
                            router.reset()
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .backgroundStyle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.setShowTutorial(true))
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .tutorialOverlay(isPresented: Binding(
            get: { store.state.showTutorial },
            set: { store.send(.setShowTutorial($0)) }
        ))
    }
}
