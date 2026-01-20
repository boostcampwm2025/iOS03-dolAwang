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
                Group {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        CameraHomeView()
                    } else {
                        AdvertiserHomeView()
                    }
                }
                .environment(router)
                .navigationDestination(for: CameraRoute.self) { viewType in
                    switch viewType {
                    case .browsing:
                        BrowsingView()
                            .environment(router)
                    case .advertising:
                        AdvertiserHomeView()
                            .environment(router)
                    case .connectionList(let list, let browser):
                        ConnectionCheckView(list, browser: browser)
                            .environment(router)
                    case .completion:
                        StreamingCompletionView()
                            .environment(router)
                    }
                }
                .navigationDestination(for: MirroringRoute.self) { viewType in
                    switch viewType {
                    case .modeSelection(let advertiser):
                        ModeSelectionView(advertiser: advertiser)
                            .environment(router)
                    case .streaming(let advertiser, let isTimerMode):
                        StreamingView(advertiser: advertiser, isTimerMode: isTimerMode)
                            .environment(router)
                            .onAppear {
                                AppDelegate.unlockOrientation()
                            }
                            .onDisappear {
                                AppDelegate.lockOrientation()
                            }
                    case .captureResult:
                        PhotoCompositionView()
                            .environment(router)
                    case .result(let result):
                        ResultView(resultPhoto: result)
                            .environment(router)
                    }
                }
                .navigationDestination(for: RemoteRoute.self) { viewType in
                    switch viewType {
                    case .remoteCapture(let advertiser):
                        RemoteCaptureView(advertiser: advertiser)
                    }
                }
            }
            .environment(store)
            .tint(Color(.label))
        }
        .homeAlert(
            isPresented: $store.state.showTimeoutAlert,
            message: "기기 연결이 끊겼습니다.",
            cancellable: false
        ) {
            router.reset()
            store.send(.showTimeoutAlert(false))
        }
    }
}
