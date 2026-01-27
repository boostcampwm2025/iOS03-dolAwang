//
//  ShootingProgressBadge.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

// 촬영 중 표시되는 프로그래스 배지
struct ShootingProgressBadge: View {
    let countdown: Int

    var body: some View {
        HStack(spacing: 16) {
            ProgressIndicator(countdown: countdown, textColor: .white)

            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT SHOT")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(countdown)초 남음")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.5))
        }
    }
}
