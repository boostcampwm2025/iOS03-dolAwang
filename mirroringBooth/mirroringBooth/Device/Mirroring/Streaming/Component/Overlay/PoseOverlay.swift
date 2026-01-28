//
//  PoseOverlay.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

struct PoseOverlay: View {
    let poses: [Pose]

    var body: some View {
        GeometryReader { geometry in
            let currentSize = min(120, geometry.size.width / 8)
            let nextSize = min(80, geometry.size.width / 12)
            // iPad mini의 너비 687을 기준으로 작으면서, 가로모드인 경우 컴팩트 버전
            let isCompact = geometry.size.height < 687 && geometry.size.width > geometry.size.height

            if let current = poses.first {
                PoseCardView(
                    with: current,
                    in: currentSize,
                    isCurrent: true,
                    isCompact: isCompact
                )
                .overlay(alignment: .bottomTrailing) {
                    if poses.count == 2,
                       let next = poses.last {
                        PoseCardView(
                            with: next,
                            in: nextSize,
                            isCurrent: false,
                            isCompact: isCompact
                        )
                        .offset(x: currentSize + 20)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: current.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 20)
            }
        }
    }
}
