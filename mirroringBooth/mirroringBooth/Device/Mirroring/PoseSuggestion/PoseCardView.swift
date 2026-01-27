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
    private let width: CGFloat

    init(
        with pose: Pose,
        in width: CGFloat,
        isCurrent: Bool
    ) {
        self.pose = pose
        self.width = width
        self.isCurrent = isCurrent
    }

    var body: some View {
        ZStack {
            poseCard
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.black)
                    .opacity(isCurrent ? 0.3 : 0.8)
            }
            .opacity(isCurrent ? 0.6 : 0.3)
        }
    }

    @ViewBuilder
    private var poseCard: some View {
        let emojiSize: CGFloat = isCurrent ? max(40, (width / 2)) : width / 2
        let descriptionFont: CGFloat = isCurrent ? max(12, (width / 8)) : width / 8

        VStack(spacing: 10) {
            Text(pose.emoji)
                .font(.system(size: emojiSize))
                .frame(height: emojiSize + 8)
            Text(pose.presentableText)
                .font(.system(size: descriptionFont).bold())
                .frame(height: descriptionFont * 5)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: isCurrent ? max(80, width) : width)
    }
}
