//
//  CameraPreview.swift
//  mirroringBooth
//
//  Created by Liam on 12/31/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @State var cameraManager = CameraManager()
    let multipeerManager: MultipeerManager
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Button(action: {
                    cameraManager.capturePhoto()
                }) {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().fill(Color.white).frame(width: 60, height: 60))
                }
                .padding(.bottom, 30)
            }
            .onAppear {
                cameraManager.configure(
                    videoDataHandler: { data in
                        multipeerManager.sendData(data, type: 0)
                    },
                    photoDataHandler: { data in
                        multipeerManager.sendData(data, type: 1)
                    }
                )
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewUIView {
        let uiView = PreviewUIView()
        uiView.backgroundColor = .black
        uiView.videoPreviewLayer.session = session
        uiView.videoPreviewLayer.videoGravity = .resizeAspectFill
        return uiView
    }
    
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
