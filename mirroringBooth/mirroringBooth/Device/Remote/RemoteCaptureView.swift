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
    let advertiser: Advertiser

    var body: some View {
        ZStack {
            Button {
                advertiser.sendCommand(.capturePhoto)
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            Color("TextPrimary").opacity(0.8),
                            lineWidth: 1
                        )
                        .frame(width: width / 2)

                    Circle()
                        .stroke(
                            Color("buttonComponent").opacity(colorScheme == .dark ? 0.7 : 0.5),
                            lineWidth: colorScheme == .dark ? 0.5 : 1
                        )
                        .frame(width: width / 2 * (colorScheme == .dark ? 1 : 0.85))

                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundStyle(colorScheme == .dark ? Color(.systemBackground) : .primary)
                        .bold()
                }
                .frame(width: width / 2)
                .background {
                    if colorScheme == .dark {
                        Circle()
                            .fill(Color.white)
                            .frame(width: width / 2 * 1.1, height: width / 2 * 1.1)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundStyle()
    }
}

#Preview {
    RemoteCaptureView(advertiser: Advertiser(photoCacheManager: PhotoCacheManager.shared))
}
