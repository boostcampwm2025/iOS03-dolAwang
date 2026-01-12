//
//  mirroringBoothWatchApp.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI

@main
struct MirroringBoothWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchView(store: WatchViewStore(connectionManager: WatchConnectionManager()))
        }
    }
}
