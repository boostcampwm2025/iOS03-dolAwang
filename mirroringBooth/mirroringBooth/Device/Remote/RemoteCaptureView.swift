//
//  RemoteConnectionTestView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/16/26.
//

import SwiftUI

struct RemoteCaptureView: View {
    @Environment(\.colorScheme) private var colorScheme

    let advertiser: Advertiser

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        GeometryReader { geometry in
            let buttonSize = min(geometry.size.width, geometry.size.height) * 0.3

            ZStack {
                Button {
                    advertiser.sendCommand(.capturePhoto)
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color("TextPrimary").opacity(0.8), lineWidth: 1)
                            .frame(width: buttonSize)

                        Circle()
                            .stroke(
                                Color("buttonComponent").opacity(isDarkMode ? 0.7 : 0.5),
                                lineWidth: isDarkMode ? 0.5 : 1
                            )
                            .frame(width: buttonSize * (isDarkMode ? 1 : 0.85))

                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundStyle(.black)
                            .bold()
                    }
                    .frame(width: buttonSize)
                    .contentShape(Circle())
                    .background {
                        if isDarkMode {
                            Circle()
                                .fill(Color.white)
                                .frame(width: buttonSize * 1.1, height: buttonSize * 1.1)
                        } else {
                            Circle()
                                .fill(.clear)
                                .frame(width: buttonSize, height: buttonSize)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .backgroundStyle()
    }
}
