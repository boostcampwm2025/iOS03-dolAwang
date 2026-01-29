//
//  ProgressIndicator.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

// 원형 프로그래스 인디케이터
struct ProgressIndicator: View {
    let countdown: Int
    var textColor: Color = .primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 6)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: CGFloat(countdown) / 7.0)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: countdown)

            Text("\(countdown)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(textColor)
        }
    }
}
