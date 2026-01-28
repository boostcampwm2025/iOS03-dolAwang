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
        ZStack {
            Color.background.ignoresSafeArea()
            VideoDisplayLayer(buffer: store.state.buffer)
                .aspectRatio(3/4, contentMode: .fit)
                .overlay {
                    Rectangle()
                        .fill(Color.clear)
                        .border(Color.red.opacity(0.4), width: 2)
                        .aspectRatio(store.state.angle == 0 ? 16 / 13 : 11 / 8, contentMode: .fit)
                }
                .overlay(alignment: .top) {
                    headerView
                }
                .overlay(alignment: .bottom) {
                    VStack {
                        Text("가이드라인 바깥은 촬영 후 보이지 않을 수 있습니다")
                            .foregroundStyle(.gray)
                            .font(.footnote.bold())
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
                    }
                        .padding(.bottom, 10)
                }

            if store.state.transfercount >= 0 {
                TransferringOverlay(
                    receivedCount: store.state.transfercount,
                    totalCount: 10,
                    description: "사진 전송 중..."
                )
            }
        }
        .preferredColorScheme(store.state.colorScheme)
        .onAppear {
            store.send(.setColorScheme(.dark))
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
            rootStore.browser?.onRemoteHeartbeatTimeout = { [weak rootStore] in
                rootStore?.browser?.sendCommand(.switchSelectModeView)
            }
        }
        .onDisappear {
            store.send(.setColorScheme(nil))
            store.send(.stopCameraSession)
        }
        .onChange(of: UIDevice.current.orientation.rawValue) { _, value in
            withAnimation(.easeInOut(duration: 0.3)) {
                store.send(.updateAngle(rawValue: value))
            }
        }
        .onChange(of: store.state.transfercount) { _, count in
            if count >= 10 {
                onDismissByCaptureCompletion?()
                dismiss()
            }
        }
        .homeAlert(
            isPresented: Binding(
                get: { store.state.isMirroringDisconnected },
                set: { _ in }
            ),
            message: "기기 연결이 끊겼습니다.",
            cancellable: false
        ) {
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
