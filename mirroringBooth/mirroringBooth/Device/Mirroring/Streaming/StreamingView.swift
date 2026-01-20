//
//  StreamingView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

struct StreamingView: View {
    @Environment(Router.self) var router: Router
    @State private var store: StreamingStore
    @State private var showHomeAlert: Bool = false
    let advertiser: Advertiser

    private let isTimerMode: Bool

    init(advertiser: Advertiser, isTimerMode: Bool) {
        self.advertiser = advertiser
        self.isTimerMode = isTimerMode
        self._store = State(
            initialValue: StreamingStore(
                advertiser,
                decoder: H264Decoder(),
                initialPhase: isTimerMode ? .guide : .none
            )
        )
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
                    .ignoresSafeArea()
            }

            // 상단 HUD
            streamingHUD

            StreamingOverlay(
                phase: store.state.overlayPhase,
                countdownValue: store.state.countdownValue,
                shootingCountdown: store.state.shootingCountdown,
                receivedPhotoCount: store.state.receivedPhotoCount,
                totalCaptureCount: store.state.totalCaptureCount,
                onReadyTapped: {
                    store.send(.startCountdown)
                }
            )
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            store.send(.startStreaming)
        }
        .onDisappear {
            store.send(.stopStreaming)
        }
        .onChange(of: store.state.overlayPhase) { _, new in
            if new == .completed {
                router.push(to: MirroringRoute.captureResult)
            }
        }
        .homeAlert(
            isPresented: $showHomeAlert,
            message: "촬영된 사진이 모두 사라집니다.\n연결을 종료하시겠습니까?"
        ) {
            router.reset()
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
            let layoutType = StreamingLayoutType(width: geometry.size.width)
            let isShooting = isTimerMode && store.state.overlayPhase == .shooting
            let isCompact = layoutType == .compact

            ZStack {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            badgeGroup(isCompact: isCompact)

                            // 연결 끊기 버튼
                            DisconnectButtonView(
                                textFont: isCompact ? .caption : .callout,
                                backgroundColor: .black.opacity(0.5)
                            ) {
                                showHomeAlert = true
                            }
                            .padding(.horizontal, -20)
                            .padding(.vertical, -15)
                        }

                        Spacer() // medium, compact는 Spacer로 우측 정렬

                        VStack(alignment: .trailing, spacing: 0) {
                            CaptureCountBadge(
                                current: store.state.capturePhotoCount,
                                total: store.state.totalCaptureCount,
                                isCompact: isCompact
                            )

                            if (layoutType == .medium || isCompact) && isShooting {
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
        if isCompact {
            VStack(alignment: .leading, spacing: 8) {
                badgeContents(isCompact: isCompact)
            }
        } else {
            HStack(spacing: 8) {
                badgeContents(isCompact: isCompact)
            }
        }
    }

    @ViewBuilder
    private func badgeContents(isCompact: Bool) -> some View {
        DeviceStatusBadge(
            deviceName: "몽이의 iPhone",
            batteryLevel: 82,
            isConnected: false,
            isCompact: isCompact
        )

        CaptureStatusBadge(
            isTimerMode: isTimerMode,
            isCompact: isCompact
        )
    }
}
