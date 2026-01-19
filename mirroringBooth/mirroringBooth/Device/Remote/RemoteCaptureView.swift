//
//  RemoteConnectionTestView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/16/26.
//

import SwiftUI

struct RemoteCaptureView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let width: CGFloat = 200
    @State private var buttonScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    let advertiser: Advertiser

    private var baseSize: CGFloat {
        width / 2 * buttonScale
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        ZStack {
            Button {
                advertiser.sendCommand(.capturePhoto)
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color("TextPrimary").opacity(0.8), lineWidth: 1)
                        .frame(width: baseSize)

                    Circle()
                        .stroke(
                            Color("buttonComponent").opacity(isDarkMode ? 0.7 : 0.5),
                            lineWidth: isDarkMode ? 0.5 : 1
                        )
                        .frame(width: baseSize * (isDarkMode ? 1 : 0.85))

                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundStyle(isDarkMode ? Color(.systemBackground) : .primary)
                        .bold()
                        .scaleEffect(buttonScale)
                }
                .frame(width: baseSize)
                .background {
                    if isDarkMode {
                        Circle()
                            .fill(Color.white)
                            .frame(width: baseSize * 1.1, height: baseSize * 1.1)
                    }
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(buttonScale)
            .gesture(magnificationGesture)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundStyle()
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                buttonScale = min(max(newScale, 1.0), 2.0)
            }
            .onEnded { _ in
                lastScale = buttonScale
            }
    }
}

#Preview {
    RemoteCaptureView(advertiser: Advertiser(photoCacheManager: PhotoCacheManager.shared))
}
