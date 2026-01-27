//
//  TimerOverlay.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/9/26.
//

import SwiftUI

/// 오버레이 컨테이너
struct StreamingOverlay: View {
    let phases: [StreamingStore.OverlayPhase]
    let countdownValue: Int
    let shootingCountdown: Int
    let receivedPhotoCount: Int
    let totalCaptureCount: Int
    let onReadyTapped: () -> Void

    var body: some View {
        ForEach(phases) { phase in
            switch phase {
            case .guide:
                TimerGuideOverlay(onReadyTapped: onReadyTapped)
            case .countdown:
                CountdownOverlay(value: countdownValue)
            case .transferring:
                TransferringOverlay(
                    receivedCount: receivedPhotoCount,
                    totalCount: totalCaptureCount
                )
            case .poseSuggestion:
                GeometryReader { geometry in
                    PoseCardView(
                        with: Pose(
                            emoji: "📸",
                            text: "저장! 사진을 찍는 것처럼 손가락으로 사각형을 만들어주세요~"
                        ),
                        in: geometry.size,
                        isCurrent: true
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)
                }
            case .completed:
                CaptureCompleteOverlay() // 임시
            default:
                EmptyView()
            }
        }
    }
}
