//
//  VideoStreamView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

// MARK: - 아이폰에서 미러링 기기로의 비디오 스트림 기능을 구현합니다.
struct VideoStreamView: View {
    @Environment(MultipeerManager.self) var multipeerManager
    @State private var cameraManager = CameraManager()
    @State private var isCapturing = false

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
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea(edges: [.top, .horizontal])

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        guard !isCapturing else { return }
                        isCapturing = true
                        cameraManager.capturePhoto()
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .stroke(.black, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                            }
                    }
                    .disabled(isCapturing)
                    .padding(.bottom, 32)
                    Spacer()
                }
            }

            // 촬영 중 오버레이
            if isCapturing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("전송 중...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            bindCameraOutputs()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
            unbindCameraOutputs()
        }
    }
    
    private func bindCameraOutputs() {
        cameraManager.onEncodedData = { data in
            multipeerManager.sendStreamData(data)
        }

        cameraManager.onCapturedPhoto = { photoData in
            multipeerManager.sendPhotoResource(photoData)
            DispatchQueue.main.async {
                isCapturing = false
            }
        }
    }

    private func unbindCameraOutputs() {
        cameraManager.onEncodedData = nil
        cameraManager.onCapturedPhoto = nil
    }
}

#Preview {
    VideoStreamView()
        .environment(MultipeerManager())
}
