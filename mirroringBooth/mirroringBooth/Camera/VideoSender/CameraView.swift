//
//  CameraView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

/// 비디오 송신 측 화면 (iPhone)
/// 카메라로부터 영상을 캡처하여 H.264로 인코딩 후 다른 기기로 전송
struct CameraView: View {

    /// 카메라 캡처 및 인코딩 담당
    private var camera = LiveVideoSource()
    private let connectionManager: Browser

    init(_ connectionManager: Browser) {
        self.connectionManager = connectionManager
        // 인코딩된 프레임을 네트워크로 전송
        camera.onEncodedFrame = { data in
            connectionManager.sendVideo(data)
        }
    }
    
    var body: some View {
        VStack {
            Text("미러링 기기에 촬영 화면이 표시됩니다.")
                .padding()
        }
        .onAppear {
            // 화면이 나타날 때 카메라 세션 시작
            do {
                try camera.startSession()
            } catch {
                print("Failed to start camera session: \(error)")
            }
        }
        .onDisappear {
            // 화면이 사라질 때 카메라 세션 중지
            camera.stopSession()
        }
    }
}

#Preview {
    CameraView(ConnectionManager())
}
