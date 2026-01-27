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
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.5)) {
                HStack(alignment: .bottom, spacing: 12) {
                    if let current = poses.first {
                        PoseCardView(
                            with: current,
                            in: min(120, geometry.size.width / 8),
                            isCurrent: true
                        )
                    }

                    if poses.count == 2,
                       let next = poses.last {
                        PoseCardView(
                            with: next,
                            in: min(80, geometry.size.width / 12),
                            isCurrent: false
                        )
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

