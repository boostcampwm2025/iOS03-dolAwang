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
    @Environment(Router.self) private var router
    @Environment(RootStore.self) private var rootStore
    @State var store: CameraPreviewStore

    let onDismissByCaptureCompletion: (() -> Void)?

    init(store: CameraPreviewStore, onDismissByCaptureCompletion: (() -> Void)? = nil) {
        _store = State(initialValue: store)
        self.onDismissByCaptureCompletion = onDismissByCaptureCompletion
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VideoDisplayLayer(buffer: store.state.buffer)
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(alignment: .top) {
                    headerView
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
        .overlay(alignment: .topTrailing) {
            exitButton
                .padding(4)
        }
        .onAppear {
            store.send(.resetCaptureCompleted)
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: true)) {
                store.send(.startAnimation)
            }
            store.send(.startSession)
            store.send(.updateAngle(rawValue: UIDevice.current.orientation.rawValue))
            rootStore.browser?.onHeartbeatTimeout = { [weak store, weak rootStore] in
                store?.send(.isMirroringDisconnected)
                rootStore?.browser?.disconnect(useType: .remote)
            }
            rootStore.browser?.onRemoteHeartbeatTimeout = {
                rootStore.browser?.sendCommand(.switchSelectModeView)
            }
        }
        .onChange(of: UIDevice.current.orientation.rawValue) { _, value in
            withAnimation(.easeInOut(duration: 0.3)) {
                store.send(.updateAngle(rawValue: value))
            }
        }
        .onChange(of: store.state.isCaptureCompleted) { _, isCompleted in
            if isCompleted {
                onDismissByCaptureCompletion?()
                dismiss()
            }
        }
        .homeAlert(
            isPresented: Binding(
                get: { store.state.showHomeAlert },
                set: { _ in }
            ),
            message: "촬영된 사진이 모두 사라집니다.\n계속하시겠습니까?"
        ) {
            store.send(.stopCameraSession)
            rootStore.send(.disconnect)
            dismiss()
            router.reset()
        }
        .homeAlert(
            isPresented: Binding(
                get: { store.state.isMirroringDisconnected },
                set: { _ in }
            ),
            message: "기기 연결이 끊겼습니다.",
            cancellable: false
        ) {
            store.send(.stopCameraSession)
            dismiss()
            router.reset()
        }
    }

    @ViewBuilder
    private var headerView: some View {
        Text("LIVE")
            .foregroundStyle(.orange)
            .font(.footnote.bold())
            .padding(.vertical, 2)
            .padding(.horizontal, 10)
            .background {
                Capsule()
                    .fill(Color.black.opacity(0.5))
            }
            .rotationEffect(Angle(degrees: store.state.angle))
            .padding(.top)
    }

    private var exitButton: some View {
        Button {
            store.send(.exit)
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
