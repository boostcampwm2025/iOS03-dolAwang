//
//  CameraPreview.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import AVFoundation
import SwiftUI

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

#Preview {
    VideoStreamView()
        .environment(MultipeerManager())
}
