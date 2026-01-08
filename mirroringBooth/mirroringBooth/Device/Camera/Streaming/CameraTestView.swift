//
//  CameraTestView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

// MARK: - 임시 카메라 프리뷰
import AVFoundation
import SwiftUI

// 임시 카메라 프리뷰
struct CameraTestView: View {
    let browser: Browser
    @State private var cameraManager = CameraManager()
    @State private var isTransferring = false

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)

            // 전송 중 오버레이
            if isTransferring {
                transferOverlay
            }
        }
        .onAppear {
            setupCallbacks()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - 전송 중 오버레이

    private var transferOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("사진 전송 중...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(cameraManager.transferProgress.current) / \(cameraManager.transferProgress.total)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - 콜백 설정

    private func setupCallbacks() {
        // 비디오 스트림 콜백
        cameraManager.onEncodedData = { data in
            guard !isTransferring else { return }
            browser.sendStreamData(data)
        }

        // 촬영 명령 수신
        browser.onCaptureCommand = {
            cameraManager.capturePhoto()
        }

        // 일괄 전송 시작 명령 수신
        browser.onStartTransferCommand = {
            isTransferring = true
            cameraManager.sendAllPhotos(using: browser)
        }

        // 전송 완료
        cameraManager.onTransferCompleted = {
            isTransferring = false
        }

        // 12장 모두 저장 완료 시 iPad에 알림 전송
        cameraManager.onAllPhotosStored = { _ in
            browser.sendCommand(.allPhotosStored)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 레이어 프레임은 layoutSubviews에서 자동 처리됨
    }

    /// AVCaptureVideoPreviewLayer를 layer로 사용하는 UIView
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let previewLayer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected AVCaptureVideoPreviewLayer, got \(type(of: layer))")
            }
            return previewLayer
        }
    }
}
