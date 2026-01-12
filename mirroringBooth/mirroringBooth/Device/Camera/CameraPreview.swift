//
//  CameraPreview.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/8/26.
//

import AVFoundation
import Combine
import SwiftUI

struct CameraPreview: View {
    let device: String
    @Environment(\.dismiss) private var dismiss
    @Environment(CameraManager.self) var manager
    @State private var decoder = H264Decoder()
    @State private var animation = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VideoDisplayLayer(decoder: decoder)
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(alignment: .top) {
                    ZStack(alignment: .trailing) {
                        HStack {
                            Spacer()
                            Text("LIVE")
                                .foregroundStyle(.orange)
                                .font(.footnote.bold())
                                .padding(.vertical, 2)
                                .padding(.horizontal, 10)
                                .background {
                                    Capsule()
                                        .fill(Color.black.opacity(0.5))
                                }
                            Spacer()
                        }
                        exitButton
                    }
                    .padding()
            }
            .overlay(alignment: .bottom) {
                Text("\(device) 연결됨")
                    .foregroundStyle(Color.remote)
                    .font(.footnote.bold())
                    .opacity(animation ? 1 : 0.4)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    }
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: true)) {
                animation = true
            }
            manager.startSession()
            manager.onEncodedData = { data in
                decoder.decode(data)
            }
        }
    }

    private var exitButton: some View {
        Button {
            manager.stopSession()
            decoder.stop()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.footnote.bold())
                .foregroundColor(.white)
                .padding(10)
                .background {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                }
        }
    }
}

private struct VideoDisplayLayer: UIViewRepresentable {
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
            displayLayer.setAffineTransform(CGAffineTransform(rotationAngle: .pi / 2))
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
