//
//  PoseCardView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

import SwiftUI

struct PoseCardView: View {
    private let isCurrent: Bool
    private let pose: Pose
    private let size: CGSize

    private var isPortrait: Bool {
        size.width < size.height
    }

    init(
        with pose: Pose,
        in size: CGSize,
        isCurrent: Bool
    ) {
        self.pose = pose
        self.size = size
        self.isCurrent = isCurrent
    }

    var body: some View {
        ZStack {
            poseCard

            if !isCurrent {
                nextBadge
            }
        }
        .frame(
            maxWidth: max(
                130,
                (isPortrait ? size.width / 6 : size.width / 3)
            ),
            maxHeight: max(
                160,
                (isPortrait ? size.height / 6 : size.height / 3)
            )
        )
    }

    @ViewBuilder
    private var poseCard: some View {
        let emojiSize: CGFloat = max(40, (size.width / 16))
        let descriptionFont: CGFloat = max(12, (size.width / 70))

        VStack(spacing: 10) {
            Text(pose.emoji)
                .font(.system(size: emojiSize))
                .frame(height: emojiSize + 8)
            Text(pose.presentableText)
                .font(.system(size: descriptionFont).bold())
                .frame(height: descriptionFont * 5)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.gray)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(isCurrent ? .main : .white, lineWidth: 5)
        }
        .opacity(isCurrent ? 0.6 : 0.4)
    }

    private var nextBadge: some View {
        Text("다음")
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .font(.system(size: max(25, (size.width / 40)), weight: .heavy))
            .foregroundStyle(.white)
            .background {
                Capsule()
                    .fill(Color.mirroring)
            }
            .opacity(0.8)
    }
}
