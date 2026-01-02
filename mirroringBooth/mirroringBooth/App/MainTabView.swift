//
//  MainTabView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2025-12-27.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var multipeerManager = MultipeerManager()

    var body: some View {
        TabView {
            DeviceTabView()
                .environment(multipeerManager)
                .tabItem {
                    Label("기기", systemImage: "dot.radiowaves.left.and.right")
                }

            PhotoMirrorView()
                .environment(multipeerManager)
                .tabItem {
                    Label("사진", systemImage: "photo")
                }

            VideoStreamView()
                .environment(multipeerManager)
                .tabItem {
                    Label("스트림", systemImage: "video")
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                multipeerManager.stopSearching()
            case .active:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    MainTabView()
}
