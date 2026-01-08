//
//  StreamingView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

struct StreamingView: View {
    @State private var store: StreamingStore
    let advertisier: Advertisier

    private let isTimerMode: Bool

    /// 총 사진 촬영 수
    private let totalCaptureCount = 12
    /// 현재까지 촬영한 사진 개수
    @State private var captureCount: Int = 0

    init(advertisier: Advertisier, isTimerMode: Bool) {
        self.advertisier = advertisier
        self.isTimerMode = isTimerMode
        // 디코더는 임시로 생성합니다.
        _store = State(initialValue: StreamingStore(advertisier, decoder: H264Decoder()))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 스트리밍 영역 배경
            Color("Background")
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
                    onReadyTapped: {
                        store.send(.startCountdown)
                    }
                )
            }
        }
        .onAppear {
            store.send(.startStreaming)
        }
        .onChange(of: store.state.timerPhase) { _, newPhase in
            if newPhase == .completed {
                // 촬영 결과 화면으로 이동
                print("12장 사진 촬영 완료")
            }
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
                .foregroundStyle(Color("Indigo"))

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
            let isCompact = geometry.size.width < 500

            VStack {
                HStack(alignment: .top) {
                    if isCompact {
                        // 아이폰 가로모드와 같이 폭이 좁은 기기는 연결 상태, 배터리 상태 뱃지를 세로로 배치합니다.
                        VStack(alignment: .leading, spacing: 8) {
                            badgeGroup(isCompact: isCompact)
                        }
                    } else {
                        badgeGroup(isCompact: isCompact)
                    }
                    Spacer()
                    CaptureCountBadge(
                        current: captureCount,
                        total: totalCaptureCount,
                        isCompact: isCompact
                    )
                }
                Spacer()
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
        Button {
            advertisier.sendCommand(.capturePhoto)
        } label: {
            Text("임시 촬영 버튼")
        }
    }
}
