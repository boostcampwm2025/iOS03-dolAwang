//
//  TimerGuideOverlay.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

/// 가이드라인 오버레이
struct TimerGuideOverlay: View {
    let onReadyTapped: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("지금부터 80초 동안")
                        .font(.title2)
                    Text("8초 간격으로 사진을 촬영합니다!")
                        .font(.title)
                        .fontWeight(.bold)
                }

                Text("준비되었으면 아래 버튼을 눌러주세요!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Button {
                    onReadyTapped()
                } label: {
                    Text("준비 완료")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                .padding(.top, 16)
            }
            .foregroundStyle(.white)
        }
    }
}
