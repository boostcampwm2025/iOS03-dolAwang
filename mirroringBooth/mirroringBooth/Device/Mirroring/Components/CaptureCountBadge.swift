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

    var body: some View {
        Text("\(current) / \(total)")
            .font(isCompact ? .caption : .subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(.black.opacity(0.5)))
    }
}
