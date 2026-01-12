//
//  WatchConnectionButton.swift
//  mirroringBooth
//
//  Created by 이상유 on 1/12/26.
//

import SwiftUI

struct WatchConnectionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                VStack(spacing: 5) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.largeTitle.bold())

                    Text("검색 가능 모드")
                        .font(.headline)
                }

                Text("다른 기기에서 검색 가능한 상태로 전환")
                    .font(.footnote)
                    .opacity(0.7)
            }
            .padding()
        }
    }
}
