//
//  MainTabView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2025-12-27.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DeviceTabView()
                .tabItem {
                    Label("기기", systemImage: "dot.radiowaves.left.and.right")
                }

            PhotoMirrorView()
                .tabItem {
                    Label("사진", systemImage: "photo")
                }

            VideoStreamView()
                .tabItem {
                    Label("스트림", systemImage: "video")
                }
        }
    }
}

#Preview {
    MainTabView()
}
