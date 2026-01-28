//
//  TransferringOverlay.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

// 사진 전송 중 표시되는 오버레이
struct TransferringOverlay: View {
    let receivedCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("사진 수신 중...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(receivedCount) / \(totalCount)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
