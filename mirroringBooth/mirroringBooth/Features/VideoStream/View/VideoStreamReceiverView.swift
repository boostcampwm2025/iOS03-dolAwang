//
//  VideoStreamReceiverView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import SwiftUI
import AVFoundation

// MARK: - iPad나 Mac에 수신된 비디오 스트림을 표시하는 View
struct VideoStreamReceiverView: View {
    @Environment(MultipeerManager.self) var multipeerManager
    @State private var decoder = H264Decoder()
    @State private var receivedCount = 0

    var body: some View {
        VideoDisplayLayer(decoder: decoder)
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                Text("[디버깅 오버레이] 수신: \(receivedCount)") // 수신이 잘되고 있는지 확인하기 위한 View입니다. (성공적으로 수신 시 숫자가 계속 증가)
                    .font(.caption)
                    .padding(8)
                    .background(.black.opacity(0.5))
                    .foregroundStyle(.white)
                    .padding()
            }
            .onAppear {
                multipeerManager.onReceivedStreamData = { data in
                    receivedCount += 1
                    decoder.decode(data)
                }
                decoder.start()
            }
            .onDisappear {
                decoder.stop()
                multipeerManager.onReceivedStreamData = nil
            }
    }
}

/// AVSampleBufferDisplayLayer를 사용하는 UIViewRepresentable
struct VideoDisplayLayer: UIViewRepresentable {
    let decoder: H264Decoder

    func makeUIView(context: Context) -> DisplayView {
        let view = DisplayView()
        context.coordinator.displayLayer = view.displayLayer
        context.coordinator.setupDecoder(decoder)
        return view
    }

    func updateUIView(_ uiView: DisplayView, context: Context) {
        // 레이어 프레임은 layoutSubviews에서 자동 처리됨
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// AVSampleBufferDisplayLayer를 layer로 사용하는 UIView
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
            backgroundColor = .black
            displayLayer.videoGravity = .resizeAspect
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class Coordinator {
        var displayLayer: AVSampleBufferDisplayLayer?

        func setupDecoder(_ decoder: H264Decoder) {
            decoder.onDecodedSampleBuffer = { [weak self] sampleBuffer in
                DispatchQueue.main.async {
                    guard let layer = self?.displayLayer else { return }

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
    }
}

#Preview {
    VideoStreamReceiverView()
        .environment(MultipeerManager())
}

