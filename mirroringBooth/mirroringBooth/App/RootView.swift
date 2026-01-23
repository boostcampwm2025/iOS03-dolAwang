//
//  RootView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct RootView: View {
    @State private var router: Router = .init()
    @State private var store: RootStore = .init()

    var body: some View {
        ZStack {
            NavigationStack(path: $router.path) {
                HomeView()
                .navigationDestination(for: CameraRoute.self) { viewType in
                    switch viewType {
                    case .browsing:
                        BrowsingView()
                    case .advertising:
                        AdvertisingView()

                    case .connectionList(let list, let browser):
                        ConnectionCheckView(list, browser: browser)
                    case .completion:
                        StreamingCompletionView()
                    }
                }
                .navigationDestination(for: MirroringRoute.self) { viewType in
                    switch viewType {
                    case .advertising:
                        AdvertisingView()
                    case .modeSelection(let advertiser, let isRemoteEnable):
                        ModeSelectionView(
                            advertiser: advertiser,
                            isRemoteModeEnabled: isRemoteEnable
                        )
                        .onAppear {
                            store.advertiser?.onHeartBeatTimeout = {
                                store.send(.showTimeoutAlert(true))
                            }
                            store.advertiser?.switchModeSelectionView = {
                                guard let advertiser = self.store.advertiser else {
                                    return
                                }
                                router.pop()
                                router.push(
                                    to: MirroringRoute.modeSelection(
                                        advertiser,
                                        isRemoteEnable: false
                                    )
                                )
                            }
                        }
                    case .streaming(let advertiser, let isTimerMode):
                        StreamingView(advertiser: advertiser, isTimerMode: isTimerMode)
                            .onAppear {
                                AppDelegate.unlockOrientation()
                            }
                            .onDisappear {
                                AppDelegate.lockOrientation()
                            }
                    case .captureResult:
                        PhotoCompositionView()
                    case .result(let result):
                        ResultView(resultPhoto: result)
                    }
                }
                .navigationDestination(for: RemoteRoute.self) { viewType in
                    switch viewType {
                    case .remoteCapture(let advertiser):
                        RemoteCaptureView(advertiser: advertiser)
                            .onAppear {
                                store.advertiser?.onHeartBeatTimeout = {
                                    store.send(.showTimeoutAlert(true))
                                }
                            }
                    case .completion:
                        CompletionView {
                            router.reset()
                        }
                    }
                }
            }
            .environment(store)
            .environment(router)
            .tint(Color(.label))
        }
        .homeAlert(
            isPresented: Binding(
                get: { store.state.showTimeoutAlert },
                set: { store.send(.showTimeoutAlert($0)) }
            ),
            message: "기기 연결이 끊겼습니다.",
            cancellable: false
        ) {
            router.reset()
            store.send(.showTimeoutAlert(false))
        }
    }
}
