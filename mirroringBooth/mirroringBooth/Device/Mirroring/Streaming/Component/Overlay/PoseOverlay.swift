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

            if let current = poses.first {
                PoseCardView(
                    with: current,
                    in: currentSize,
                    isCurrent: true
                )
                .overlay(alignment: .bottomTrailing) {
                    if poses.count == 2,
                       let next = poses.last {
                        PoseCardView(
                            with: next,
                            in: nextSize,
                            isCurrent: false
                        )
                        .offset(x: currentSize + 12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 20)
            }
        }
    }
}

