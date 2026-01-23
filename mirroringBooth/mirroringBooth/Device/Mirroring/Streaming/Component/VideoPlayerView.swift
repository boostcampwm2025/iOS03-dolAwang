//
//  VideoPlayerView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/8/26.
//

import AVFoundation
import SwiftUI

struct VideoPlayerView: UIViewRepresentable {
    let sampleBuffer: CMSampleBuffer?  // StreamingStore의 state에서 받아옵니다.
    let rotationAngle: Int16

    func makeUIView(context: Context) -> DisplayView {
        let view = DisplayView()
        context.coordinator.displayLayer = view.displayLayer
        return view
    }

    func updateUIView(_ uiView: DisplayView, context: Context) {
        context.coordinator.applyRotation(rotationAngle)
        guard let sampleBuffer = sampleBuffer else { return }
        context.coordinator.enqueue(sampleBuffer)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class DisplayView: UIView {
        override class var layerClass: AnyClass {
            AVSampleBufferDisplayLayer.self
        }

        var displayLayer: AVSampleBufferDisplayLayer {
            guard let displayLayer = layer as? AVSampleBufferDisplayLayer else {
                fatalError("Expected AVSampleBufferDisplayLayer, got \(type(of: layer))")
            }
            return displayLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = #colorLiteral(red: 0.1204712167, green: 0.160810262, blue: 0.2149580121, alpha: 1)
            // displayLayer.videoGravity = .resizeAspectFill
            displayLayer.videoGravity = .resizeAspect
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class Coordinator {
        var displayLayer: AVSampleBufferDisplayLayer?

        func applyRotation(_ rotationAngle: Int16) {
            guard let layer = displayLayer else { return }

            let radians = CGFloat(Double(rotationAngle)) * CGFloat(Double.pi) / 180.0
            layer.setAffineTransform(CGAffineTransform(rotationAngle: radians))
        }

        func enqueue(_ sampleBuffer: CMSampleBuffer) {
            guard let layer = displayLayer else { return }

            // 에러 상태면 flush 후 재시도
            if layer.status == .failed {
                layer.flush()
            }

            if layer.isReadyForMoreMediaData {
                layer.enqueue(sampleBuffer)
            }
        }
    }
}
