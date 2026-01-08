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
                            AdvertisierHomeView()
                        case .connectionList(let list, let browser):
                            ConnectionCheckView(list, browser: browser)
                            .environment(router)
                        case .streaming:
                            EmptyView()
                        }
                    }
            default:
                AdvertisierHomeView()
                    .environment(router)
                    .navigationDestination(for: MirroringRoute.self) { viewType in
                        switch viewType {
                        case .modeSelection:
                            ModeSelectionView()
                                .environment(router)
                        }
                    }
            }
        }
        .tint(.black)
    }
}
