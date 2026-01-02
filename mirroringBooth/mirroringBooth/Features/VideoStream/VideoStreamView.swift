//
//  VideoStreamView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

// 아이폰에서 미러링 기기로의 비디오 스트림 기능을 구현합니다.
struct VideoStreamView: View {
    @Environment(MultipeerManager.self) var multipeerManager
    @State private var cameraManager = CameraManager()

    var body: some View {
        Group {
            if multipeerManager.isVideoSender {
                // 아이폰일 경우 화면을 송신합니다.
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                    .task {
                        await cameraManager.startSession()
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                    }
            } else {
                // iPad나Mac일 경우 화면을 수신합니다.
                VideoStreamReceiverView()
            }
        }
    }
}

#Preview {
    VideoStreamView()
        .environment(MultipeerManager())
}

