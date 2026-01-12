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
    @Environment(\.dismiss) private var dismiss
    @State var store: CameraPreviewStore

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VideoDisplayLayer(buffer: store.state.buffer)
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
                Text("\(store.state.deviceName) 연결됨")
                    .foregroundStyle(Color.remote)
                    .font(.footnote.bold())
                    .opacity(store.state.animationFlag ? 1 : 0.4)
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
                store.send(.startAnimation)
            }
            store.send(.startSession)
        }
    }

    private var exitButton: some View {
        Button {
            store.send(.tapExitButton)
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
    let buffer: CMSampleBuffer?

    func makeUIView(context: Context) -> DisplayView {
        return DisplayView()
    }

    func updateUIView(_ uiView: DisplayView, context: Context) {
        guard let buffer = buffer else { return }
        uiView.enqueue(buffer)
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

        func enqueue(_ buffer: CMSampleBuffer) {
            let displayLayer: AVSampleBufferDisplayLayer = self.displayLayer

            if displayLayer.status == .failed {
                displayLayer.flush()
            }

            guard displayLayer.isReadyForMoreMediaData else { return }
            displayLayer.enqueue(buffer)
        }
    }
}
