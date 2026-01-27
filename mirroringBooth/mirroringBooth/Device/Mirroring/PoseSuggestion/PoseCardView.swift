//
//  PoseCardView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-26.
//

import SwiftUI

struct PoseCardView: View {
    private let isCurrent: Bool
    private let emoji: String
    private let description: String

    @State var width: CGFloat = .infinity
    @State var height: CGFloat = .infinity

    init(
        with emoji: String,
        _ description: String,
        isCurrent: Bool
    ) {
        self.emoji = emoji
        self.description = description
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
            Text(emoji)
                .font(.system(size: emojiSize))
                .frame(height: emojiSize + 8)
            Text(description)
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
        with: "📸",
        "저장!\n사진을 찍는 것처럼 손가락으로 사각형을 만들어주세요~",
        isCurrent: true
    )
}
