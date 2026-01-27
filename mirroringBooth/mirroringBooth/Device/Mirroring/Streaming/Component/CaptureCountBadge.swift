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
        isCompact ? 110 : 120
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("남은 촬영 횟수")
                .font(isCompact ? .footnote : .subheadline)
            Text("\(total - current)")
                .font(isCompact ? .title2 : .title)
        }
        .foregroundStyle(.white)
        .frame(width: badgeSize, height: badgeSize)
        .background {
            Circle()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Circle()
                .strokeBorder(.white, lineWidth: 3)
        }
        .preferredColorScheme(.dark)
    }
}
