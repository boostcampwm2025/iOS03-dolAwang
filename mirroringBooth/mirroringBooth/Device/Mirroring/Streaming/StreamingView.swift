//
//  StreamingView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

struct StreamingView: View {
    @State private var store: StreamingStore
    let advertiser: Advertiser

    private let isTimerMode: Bool

    init(advertiser: Advertiser, isTimerMode: Bool) {
        self.advertiser = advertiser
        self.isTimerMode = isTimerMode
        _store = State(initialValue: StreamingStore(advertiser, decoder: H264Decoder()))
    }

    private enum StreamingLayoutType {
        case compact  // 아이폰 세로모드
        case medium   // 아이패드 세로모드, 작은 아이패드 가로모드
        case large    // 큰 아이패드 가로모드, MacOS

        init(width: CGFloat) {
            if width < 500 {
                self = .compact
            } else if width < 1100 {
                self = .medium
            } else {
                self = .large
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 스트리밍 영역 배경
            Color("background")
                .ignoresSafeArea()

            // 비디오 스트리밍 표시
            if let sampleBuffer = store.state.currentSampleBuffer {
                VideoPlayerView(sampleBuffer: sampleBuffer)
                    .ignoresSafeArea()
            } else {
                streamingPlaceholder
            }

            // 상단 HUD
            streamingHUD

            // 타이머 모드 오버레이
            if isTimerMode {
                TimerOverlay(
                    phase: store.state.timerPhase,
                    countdownValue: store.state.countdownValue,
                    shootingCountdown: store.state.shootingCountdown,
                    receivedPhotoCount: store.state.receivedPhotoCount,
                    totalCaptureCount: store.state.totalCaptureCount,
                    onReadyTapped: {
                        store.send(.startCountdown)
                    }
                )
            }
        }
        .onAppear {
            store.send(.startStreaming)
        }
        .onDisappear {
            store.send(.stopStreaming)
        }
    }

    // MARK: - 비디오 스트리밍 영역

    /// 비디오 연결 전에 보여줄 안내 메시지
    private var streamingPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.fill")
                .font(.largeTitle)
                .foregroundStyle(Color("mainColor"))

            Text("스트리밍 표시 영역")
                .font(.title3)
                .fontWeight(.semibold)

            Text("촬영 기기(iPhone)에서 전송 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }

    /// 스트리밍 영역 상단 HUD
    private var streamingHUD: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let layoutType = StreamingLayoutType(width: screenWidth)
            let isShooting = isTimerMode && store.state.timerPhase == .shooting

            ZStack {
                VStack {
                    HStack(alignment: .top) {
                        if layoutType == .compact {
                            // 뱃지를 세로로 배치
                            VStack(alignment: .leading, spacing: 8) {
                                badgeGroup(isCompact: true)
                            }
                        } else {
                            badgeGroup(isCompact: false)
                        }

                        Spacer() // medium, compact는 Spacer로 우측 정렬

                        VStack(alignment: .trailing, spacing: 0) {
                            CaptureCountBadge(
                                current: store.state.captureCount,
                                total: store.state.totalCaptureCount,
                                isCompact: layoutType == .compact
                            )

                            if (layoutType == .medium || layoutType == .compact) && isShooting {
                                if layoutType == .compact {
                                    ProgressIndicator(countdown: store.state.shootingCountdown)
                                        .padding(.top, 16)
                                } else {
                                    ShootingProgressBadge(countdown: store.state.shootingCountdown)
                                        .padding(.top, 16)
                                }
                            }
                        }
                    }
                    Spacer()
                }

                if layoutType == .large && isShooting {
                    VStack {
                        ShootingProgressBadge(countdown: store.state.shootingCountdown)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func badgeGroup(isCompact: Bool) -> some View {
        DeviceStatusBadge(
            deviceName: "몽이의 iPhone",
            batteryLevel: 82,
            isConnected: false,
            isCompact: isCompact
        )
        CaptureStatusBadge(isTimerMode: isTimerMode, isCompact: isCompact)
    }
}

#Preview {
    StreamingView(advertiser: Advertiser(), isTimerMode: true)
}
