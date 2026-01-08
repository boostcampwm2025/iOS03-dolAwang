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

    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)

            // 사진 촬영 버튼
            VStack {
                Spacer()
                Button {
                    cameraManager.capturePhoto()
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 비디오 스트림 콜백
            cameraManager.onEncodedData = { data in
                browser.sendStreamData(data)
            }
            // 사진 촬영 콜백
            cameraManager.onCapturedPhoto = { data in
                browser.sendPhotoResource(data)
            }
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
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
