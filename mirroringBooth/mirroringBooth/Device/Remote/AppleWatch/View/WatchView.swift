//
//  WatchView.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/7/26.
//

import SwiftUI

struct WatchView: View {
    @State private var isConnecting = false

    var body: some View {
        if isConnecting {
            WatchConnectionView {
                isConnecting = false
            }
        } else {
            WatchConnectionButton {
                isConnecting = true
            }
        }
    }
}
