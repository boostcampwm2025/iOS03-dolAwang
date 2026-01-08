//
//  TimerOverlay.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/9/26.
//

import SwiftUI

/// 타이머 오버레이 컨테이너
struct TimerOverlay: View {
    let phase: StreamingStore.TimerPhase
    let countdownValue: Int
    let shootingCountdown: Int
    let onReadyTapped: () -> Void

    var body: some View {
        switch phase {
        case .guide:
            TimerGuideOverlay(onReadyTapped: onReadyTapped)
        case .countdown:
            CountdownOverlay(value: countdownValue)
        case .shooting:
            ShootingProgressIndicator(countdown: shootingCountdown)
        case .completed:
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
                    Text("지금부터 60초 동안")
                        .font(.title2)
                    Text("5초 간격으로 사진을 촬영합니다!")
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
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// 촬영 중 표시되는 원형 프로그래스 인디케이터
struct ShootingProgressIndicator: View {
    let countdown: Int

    var body: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 5.0)
                        .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)

                    Text("\(countdown)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 16)
                .padding(.top, 80)
            }
            Spacer()
        }
    }
}
