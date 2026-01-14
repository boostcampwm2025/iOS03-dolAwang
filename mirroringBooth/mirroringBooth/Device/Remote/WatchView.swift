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
            WatchConnectionView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Button {
                    isConnecting = false
                } label: {
                    Image(systemName: "multiply")
                        .padding()
                        .background(
                            Circle()
                                .fill(.gray)
                        )
                }
                .buttonStyle(.plain)
            }
        } else {
            WatchConnectionButton {
                isConnecting = true
            }
        }
    }
}
