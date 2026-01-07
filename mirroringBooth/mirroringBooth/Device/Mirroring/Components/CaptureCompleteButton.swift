//
//  CaptureCompleteButton.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

/// 촬영 완료 버튼
struct CaptureCompleteButton: View {
    let isComplete: Bool
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isCompact ? "완료" : "촬영 완료 및 선택")
                .font(isCompact ? .caption : .headline)
                .fontWeight(isCompact ? .semibold : .regular)
                .foregroundStyle(isComplete ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 8 : 14)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 10 : 14)
                        .fill(isComplete ? Color("Indigo") : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 10 : 14)
                                .stroke(
                                    style: StrokeStyle(
                                        lineWidth: 1.5,
                                        dash: isComplete ? [] : [5, 5]
                                    )
                                )
                                .foregroundStyle(.white.opacity(isComplete ? 0 : 0.5))
                        )
                )
        }
        .disabled(!isComplete)
    }
}
