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
    /// 현재 선택된 포즈 가이드
    @State private var selectedPose: Pose = .none

    private let landscapeThreshold: CGFloat = 800

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let isLandscape = width > height

            Group {
                // iPad 가로 또는 Mac일 경우
                if width >= landscapeThreshold && isLandscape {
                    horizontalLayout
                // iPhone 가로일 경우
                } else if isLandscape {
                    compactHorizontalLayout
                // iPhone, iPad가 세로일 경우
                } else {
                    verticalLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color("Background"))
        .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
    }

    // MARK: - 레이아웃

    /// iPad 가로모드 + Mac용 레이아웃
    private var horizontalLayout: some View {
        HStack(spacing: 24) {
            streamingArea
            sidePanel(compact: false)
                .frame(width: 280)
        }
        .padding(24)
    }

    /// iPhone 가로모드용 컴팩트 레이아웃
    private var compactHorizontalLayout: some View {
        HStack(spacing: 12) {
            streamingArea
            sidePanel(compact: true)
                .frame(width: 200)
        }
        .padding(12)
    }

    /// iPhone/iPad 세로모드용 레이아웃
    private var verticalLayout: some View {
        VStack(spacing: 16) {
            streamingArea
            sidePanel(compact: false)
        }
        .padding(16)
    }

    // MARK: - 비디오 스트리밍 영역

    /// 비디오 스트리밍 표시 영역
    private var streamingArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))

            streamingPlaceholder

            // 포즈 가이드라인 표시
            if selectedPose != .none, let imageName = selectedPose.imageName {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .foregroundStyle(.white.opacity(0.2))
            }

            // 상단 정보 표시 (연결 상태, 촬영 수)
            streamingHUD
        }
        .aspectRatio(16/9, contentMode: .fit)
    }

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
        VStack {
            HStack {
                DeviceStatusBadge(
                    deviceName: "내 iPhone",
                    batteryLevel: 82,
                    isConnected: true
                )

                Spacer()

                CaptureCountBadge(
                    current: captureCount,
                    total: totalCaptureCount
                )
            }
            .padding(16)

            Spacer()
        }
    }

    // MARK: - 사이드 패널 영역

    /// 사이드 패널
    /// - compact: false인 경우는 iPad 가로/세로, iPhone 세로 전용
    /// - compact: true인 경우는 iPhone 가로 전용
    private func sidePanel(compact: Bool) -> some View {
        let spacing: CGFloat = compact ? 12 : 16
        let padding: CGFloat = compact ? 12 : 16

        return VStack(spacing: spacing) {
            poseGuideSection(compact: compact)
            Spacer()
            CaptureCompleteButton(
                isComplete: captureCount >= totalCaptureCount,
                isCompact: compact,
                action: {
                    // 촬영 완료 후 사진 선택 화면으로 이동
                }
            )
        }
        .padding(padding)
    }

    /// 포즈 가이드 섹션
    /// - compact: false인 경우는 아이콘 + 텍스트 표시 (adaptive 그리드)
    /// - compact: true인 경우는 아이콘 없이 텍스트만 표시 (2열 그리드)
    private func poseGuideSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            // 섹션 타이틀
            HStack(spacing: 4) {
                Image(systemName: "person")
                    .foregroundStyle(Color("TextPrimary"))

                Text("포즈 가이드")
                    .font(compact ? .caption : .headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))
            }

            LazyVGrid(
                columns: compact
                    ? [GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.adaptive(minimum: 120))],
                spacing: compact ? 8 : 12
            ) {
                ForEach(Pose.allCases) { pose in
                    PoseButton(
                        pose: pose,
                        isSelected: pose == selectedPose,
                        isCompact: compact,
                        action: {
                            selectedPose = pose
                        }
                    )
                }
            }
        }
    }
}
