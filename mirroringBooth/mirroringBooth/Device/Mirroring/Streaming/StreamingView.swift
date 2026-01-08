//
//  StreamingView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

struct StreamingView: View {
    /// 총 사진 촬영 수
    private let totalCaptureCount = 10
    /// 현재까지 촬영한 사진 개수
    private var captureCount: Int = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // 스트리밍 영역 배경
            Color("Background")
                .ignoresSafeArea()

            streamingPlaceholder // 비디오 스트리밍이 오면 해당 Placeholder를 변경

            // 상단 HUD
            streamingHUD
        }
    }

    // MARK: - 비디오 스트리밍 영역

    /// 비디오 연결 전에 보여줄 안내 메시지
    private var streamingPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.main)

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
        CaptureStatusBadge(isTimerMode: true, isCompact: isCompact)
    }
}
