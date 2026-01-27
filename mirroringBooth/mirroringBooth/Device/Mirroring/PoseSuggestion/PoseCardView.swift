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

    @State var width: CGFloat = .infinity
    @State var height: CGFloat = .infinity

    init(
        with pose: Pose,
        isCurrent: Bool
    ) {
        self.pose = pose
        self.isCurrent = isCurrent
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                poseCard
                    .onAppear {
                        width = geometry.size.width
                        height = geometry.size.height
                    }

                if !isCurrent {
                    nextBadge
                }
            }
        }
        .frame(
            maxWidth: max(130, (width > height ? width / 3 : width / 6)),
            maxHeight: max(160, (width > height ? height / 3 : height / 6))
        )
    }

    @ViewBuilder
    private var poseCard: some View {
        let emojiSize: CGFloat = max(40, (width / 16))
        let descriptionFont: CGFloat = max(12, (width / 70))

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
            .font(.system(size: max(25, (width / 40)), weight: .heavy))
            .foregroundStyle(.white)
            .background {
                Capsule()
                    .fill(Color.mirroring)
            }
            .opacity(0.8)
    }
}

#Preview {
    PoseCardView(
        with: Pose(
            emoji: "📸",
            text: "저장! 사진을 찍는 것처럼 손가락으로 사각형을 만들어주세요~"
        ),
        isCurrent: true
    )
}
