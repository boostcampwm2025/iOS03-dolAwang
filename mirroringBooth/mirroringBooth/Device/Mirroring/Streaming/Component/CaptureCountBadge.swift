//
//  CaptureCountBadge.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

/// 촬영 진행 상황 표시
struct CaptureCountBadge: View {
    let current: Int
    let total: Int
    let isCompact: Bool

    private var badgeSize: CGFloat {
        isCompact ? 90 : 100
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("남은 촬영 횟수")
                .font(isCompact ? .caption2 : .caption)
                .opacity(0.8)
            Text("\(total - current)")
                .font(isCompact ? .title3 : .title)
        }
        .foregroundStyle(.primary)
        .frame(width: badgeSize, height: badgeSize)
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.3), lineWidth: 2)
        }
    }
}
