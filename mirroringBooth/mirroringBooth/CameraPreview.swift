//
//  CameraPreview.swift
//  mirroringBooth
//
//  Created by 최윤진 on 12/22/25.
//

import SwiftUI
import CoreImage
import CoreImage

struct CameraPreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image?
    @State private var displayLink: CADisplayLink?
    private let ciContext = CIContext()
    private let provider: () -> CIImage?
    var tapCameraButton: (() -> Void)?

    init(_ provider: @escaping () -> CIImage?, tapCameraButton: (() -> Void)? = nil) {
        self.provider = provider
        self.tapCameraButton = tapCameraButton
    }

    var body: some View {
        ZStack {
            Group {
                if let renderedImage = renderedImage {
                    renderedImage
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .trailing) {
                Button {
                    self.stopDisplayLink()
                    dismiss()
                } label: {
                    Text("닫기")
                }
                .buttonStyle(.borderedProminent)
                .padding()
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        tapCameraButton?()
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .strokeBorder(Color.gray, lineWidth: 3)
                            .frame(width: 60)
                    }
                    Spacer()
                }
                .frame(height: 60)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            self.startDisplayLink()
        }
    }

    private func startDisplayLink() {
        let proxy = DisplayLinkProxy { [provider, ciContext] in
            guard let ciImage = provider() else { return }
            guard let cgImage = ciContext.createCGImage(
                ciImage,
                from: ciImage.extent
            ) else { return }
            self.renderedImage = Image(decorative: cgImage, scale: 1.0, orientation: .up)
        }

        let displayLink = CADisplayLink(
            target: proxy,
            selector: #selector(DisplayLinkProxy.tick)
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func pullAndRenderLatestFrame() {
        guard let ciImage = provider(),
              let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { return }
        renderedImage = Image(decorative: cgImage, scale: 1.0, orientation: .up)
    }
}

private final class DisplayLinkProxy: NSObject {
    private let onTick: () -> Void

    init(onTick: @escaping () -> Void) {
        self.onTick = onTick
        super.init()
    }

    @objc func tick() {
        self.onTick()
    }
}

#Preview {
    CameraPreview { nil }
}
