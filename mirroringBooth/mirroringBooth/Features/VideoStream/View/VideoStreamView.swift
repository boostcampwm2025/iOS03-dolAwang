//
//  VideoStreamView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

/// 아이폰에서 미러링 기기로의 비디오 스트림 기능을 구현합니다.
struct VideoStreamView: View {
    @Environment(MultipeerManager.self) var multipeerManager
    @State private var cameraManager = CameraManager()

    var body: some View {
        Group {
            if !multipeerManager.isConnected {
                notConnectedView
            } else if multipeerManager.isVideoSender {
                senderView
            } else {
                VideoStreamReceiverView()
            }
        }
    }

    /// 연결되지 않은 상태일 경우
    private var notConnectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("기기가 연결되지 않았습니다")
                .font(.headline)
            Text("기기 탭에서 먼저 연결해주세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// 카메라 화면을 캡처하고 송신합니다.
    private var senderView: some View {
        CameraPreview(session: cameraManager.session)
            .ignoresSafeArea(edges: [.top, .horizontal])
            .task {
                cameraManager.onEncodedData = { data in
                    multipeerManager.sendStreamData(data)
                }
                await cameraManager.startSession()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
    }
}

#Preview {
    VideoStreamView()
        .environment(MultipeerManager())
}

