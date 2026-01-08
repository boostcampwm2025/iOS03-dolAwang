//
//  RootView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct RootView: View {
    @State private var router: Router = .init()
    @State private var advertiser = Advertiser() // 임시 생성

    var body: some View {
        NavigationStack(path: $router.path) {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                CameraHomeView()
                    .environment(router)
                    .navigationDestination(for: CameraRoute.self) { viewType in
                        switch viewType {
                        case .browsing:
                            BrowsingView()
                                .environment(router)
                        case .advertising:
                            AdvertiserHomeView()
                        case .connectionList(let list, let browser):
                            ConnectionCheckView(list, browser: browser)
                            .environment(router)
                        case .streaming:
                            EmptyView()
                        }
                    }
            default:
                AdvertiserHomeView()
                    .environment(router)
                    .environment(advertiser)
                    .navigationDestination(for: MirroringRoute.self) { viewType in
                        switch viewType {
                        case .modeSelection:
                            ModeSelectionView()
                                .environment(router)
                        case .streaming(let isTimerMode):
                            StreamingView(advertiser: advertiser, isTimerMode: isTimerMode)
                        }
                    }
            }
        }
        .tint(.black)
    }
}
