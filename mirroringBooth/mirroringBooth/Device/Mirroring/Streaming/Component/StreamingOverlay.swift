//
//  TimerOverlay.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/9/26.
//

import SwiftUI

/// 오버레이 컨테이너
struct StreamingOverlay: View {
    let phase: StreamingStore.OverlayPhase
    let countdownValue: Int
    let shootingCountdown: Int
    let receivedPhotoCount: Int
    let totalCaptureCount: Int
    let onReadyTapped: () -> Void

    var body: some View {
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
        case .completed:
            CaptureCompleteOverlay() // 임시
        default:
            EmptyView()
        }
    }
}

/// 가이드라인 오버레이
struct TimerGuideOverlay: View {
    let onReadyTapped: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("지금부터 80초 동안")
                        .font(.title2)
                    Text("8초 간격으로 사진을 촬영합니다!")
                        .font(.title)
                        .fontWeight(.bold)
                }

                Text("준비되었으면 아래 버튼을 눌러주세요!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Button {
                    onReadyTapped()
                } label: {
                    Text("준비 완료")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                .padding(.top, 16)
            }
            .foregroundStyle(.white)
        }
    }
}

// 카운트다운 오버레이
struct CountdownOverlay: View {
    let value: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            Text("\(value)초 뒤에 사진을 촬영합니다!")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// 촬영 중 표시되는 프로그래스 배지
struct ShootingProgressBadge: View {
    let countdown: Int

    var body: some View {
        HStack(spacing: 16) {
            ProgressIndicator(countdown: countdown)

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

// 원형 프로그래스 인디케이터
struct ProgressIndicator: View {
    let countdown: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 6)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: CGFloat(countdown) / 8.0)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: countdown)

            Text("\(countdown)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
}

// 사진 전송 중 표시되는 오버레이
struct TransferringOverlay: View {
    let receivedCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("사진 수신 중...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(receivedCount) / \(totalCount)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

// 촬영 완료 시 표시되는 오버레이
// 사진 선택 화면으로 넘어가기 전 임시 오버레이입니다.
struct CaptureCompleteOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("촬영 완료!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("10장의 사진이 촬영되었습니다")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
