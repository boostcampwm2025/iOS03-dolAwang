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
    let poseSuggestion: [Pose]

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
                PoseOverlay(poses: poseSuggestion)
            case .completed:
                CaptureCompleteOverlay() // 임시
            default:
                EmptyView()
            }
        }
    }
}
