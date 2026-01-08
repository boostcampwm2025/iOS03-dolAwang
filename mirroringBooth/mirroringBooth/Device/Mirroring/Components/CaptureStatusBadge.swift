//
//  CaptureStatusBadge.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

import SwiftUI

/// 리모콘, 타이머 연걸 상태
struct CaptureStatusBadge: View {
    let isTimerMode: Bool
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isTimerMode ? "clock" : "checkmark.applewatch")
                .foregroundStyle(isTimerMode ? Color("Indigo") : .green)

            Text(isTimerMode ? "타이머 대기중" : "원격 대기")
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .font(isCompact ? .caption : nil)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(.black.opacity(0.5))
        )
    }
}
