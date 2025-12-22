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

    init(_ provider: @escaping () -> CIImage?) {
        self.provider = provider
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
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

            Button {
                dismiss()
            } label: {
                Text("닫기")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear {
            self.startDisplayLink()
        }
        .onDisappear {
            self.stopDisplayLink()
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
