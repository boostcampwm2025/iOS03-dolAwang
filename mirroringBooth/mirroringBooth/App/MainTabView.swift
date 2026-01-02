//
//  MainTabView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2025-12-27.
//

import SwiftUI

struct MainTabView: View {
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
    }
}

#Preview {
    MainTabView()
}
