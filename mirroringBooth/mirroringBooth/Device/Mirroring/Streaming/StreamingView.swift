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
        .ignoresSafeArea(.all, edges: [.bottom, .leading, .trailing])
    }

    // MARK: - 레이아웃

    /// iPad 가로모드 + Mac용 레이아웃
    private var horizontalLayout: some View {
        HStack(spacing: 24) {
            streamingArea
            sidePanel
                .frame(width: 280)
        }
        .padding(24)
    }

    /// iPhone 가로모드용 컴팩트 레이아웃
    private var compactHorizontalLayout: some View {
        HStack(spacing: 12) {
            streamingArea
            compactSidePanel
                .frame(width: 200)
        }
        .padding(12)
    }

    /// iPhone/iPad 세로모드용 레이아웃
    private var verticalLayout: some View {
        VStack(spacing: 16) {
            streamingArea
            sidePanel
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
        .foregroundStyle(.white)
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

    /// iPad 가로/세로, iPhone 세로 전용 패널
    private var sidePanel: some View {
        VStack(spacing: 16) {
            poseGuideSection
            Spacer()
            completeButton
        }
        .padding(16)
    }

    /// iPhone 가로 전용 패널
    private var compactSidePanel: some View {
        VStack(spacing: 12) {
            compactPoseGuideSection
            Spacer()
            compactCompleteButton
        }
        .padding(12)
    }

    /// 포즈 가이드 섹션
    private var poseGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 타이틀

            HStack(spacing: 4) {
                Image(systemName: "person")
                    .foregroundStyle(.white)

                Text("포즈 가이드")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(Pose.allCases) { pose in
                    PoseButton(
                        pose: pose,
                        isSelected: pose == selectedPose,
                        type: .normal,
                        action: {
                            selectedPose = pose
                        }
                    )
                }
            }
        }
    }

    /// iPhone 가로모드용 포즈 가이드 섹션
    /// 아이콘 없이 텍스트만 표시합니다.
    private var compactPoseGuideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "person")
                    .foregroundStyle(.white)

                Text("포즈 가이드")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            // 2열 그리드
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Pose.allCases) { pose in
                    PoseButton(
                        pose: pose,
                        isSelected: pose == selectedPose,
                        type: .compact,
                        action: {
                            selectedPose = pose
                        }
                    )
                }
            }
        }
    }

    /// 촬영 완료 버튼
    private var completeButton: some View {
        CaptureCompleteButton(
            isComplete: captureCount >= totalCaptureCount,
            type: .normal,
            action: {
                // 촬영 완료 후 사진 선택 화면으로 이동
            }
        )
    }

    /// 촬영 완료 버튼 (아이폰 가로모드용)
    private var compactCompleteButton: some View {
        CaptureCompleteButton(
            isComplete: captureCount >= totalCaptureCount,
            type: .compact,
            action: {
                // 촬영 완료 후 사진 선택 화면으로 이동
            }
        )
    }
}

// MARK: - 촬영 완료 버튼

/// 버튼 크기 타입
enum ButtonType {
    case normal
    case compact
}

/// 촬영 완료 버튼
struct CaptureCompleteButton: View {
    let isComplete: Bool
    let type: ButtonType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type == .compact ? "완료" : "촬영 완료 및 선택")
                .font(type == .compact ? .caption : .headline)
                .fontWeight(type == .compact ? .semibold : .regular)
                .foregroundStyle(isComplete ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, type == .compact ? 8 : 14)
                .background(
                    RoundedRectangle(cornerRadius: type == .compact ? 10 : 14)
                        .fill(isComplete ? Color("Indigo") : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: type == .compact ? 10 : 14)
                                .stroke(
                                    style: StrokeStyle(
                                        lineWidth: 1.5,
                                        dash: isComplete ? [] : [5, 5]
                                    )
                                )
                                .foregroundStyle(.white.opacity(isComplete ? 0 : 0.5))
                        )
                )
        }
        .disabled(!isComplete)
    }
}

// MARK: - 포즈 선택 버튼

/// 포즈 선택 버튼
struct PoseButton: View {
    let pose: Pose
    let isSelected: Bool
    let type: ButtonType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: type == .compact ? 0 : 8) {
                // 포즈 아이콘
                if type == .normal, let imageName = pose.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(height: 40)
                        .foregroundStyle(.white)
                }

                // 포즈 이름
                Text(pose.rawValue)
                    .font(type == .compact ? .caption2 : .caption)
                    .fontWeight(type == .compact ? .medium : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: type == .compact ? nil : 100)
            .padding(.vertical, type == .compact ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: type == .compact ? 10 : 16)
                    .fill(isSelected ? Color("Indigo") : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: type == .compact ? 10 : 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - 포즈

enum Pose: String, CaseIterable, Identifiable {
    case none = "None"
    case heart = "볼 하트"
    case vpose = "브이"
    case flower = "꽃받침"

    var id: String { rawValue }

    var imageName: String? {
        switch self {
        case .none: return nil
        case .heart: return "pose_heart"
        case .vpose: return "pose_v"
        case .flower: return "pose_flower"
        }
    }
}
