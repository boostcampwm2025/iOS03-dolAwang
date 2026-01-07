//
//  PoseButton.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

/// 포즈 선택 버튼
struct PoseButton: View {
    let pose: Pose
    let isSelected: Bool
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 0 : 8) {
                if !isCompact, let imageName = pose.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(height: 40)
                        .foregroundStyle(.white)
                }

                // 포즈 이름
                Text(pose.rawValue)
                    .font(isCompact ? .caption2 : .caption)
                    .fontWeight(isCompact ? .medium : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: isCompact ? nil : 100)
            .padding(.vertical, isCompact ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 10 : 16)
                    .fill(isSelected ? Color("Indigo") : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 10 : 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}
