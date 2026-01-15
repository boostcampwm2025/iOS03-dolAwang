//
//  RootView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct RootView: View {
    @State private var router: Router = .init()

    var body: some View {
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
                    CaptureResultView()
                        .environment(router)
                case .result(let result):
                    ResultView(resultPhoto: result)
                        .environment(router)
                }
            }
            .navigationDestination(for: RemoteRoute.self) { viewType in
                switch viewType {
                case .connectionTest(let advertiser):
                    RemoteConnectionTestView(advertiser: advertiser)
                }
            }
        }
        .tint(.black)
    }
}
