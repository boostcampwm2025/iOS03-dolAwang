//
//  StreamDisplayView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import SwiftUI

/// 디코딩된 비디오 프레임을 화면에 렌더링하는 뷰
struct StreamDisplayView: View {

    @ObservedObject private var renderer: MediaFrameRenderer
    var onCaptureRequest: (() -> Void)?

    init(renderer: MediaFrameRenderer, onCaptureRequest: (() -> Void)? = nil) {
        self.renderer = renderer
        self.onCaptureRequest = onCaptureRequest
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if let image = renderer.currentFrame {
                    Image(decorative: image, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .background(Color.black)

            // 촬영 버튼
            VStack {
                Spacer()

                Button {
                    onCaptureRequest?()
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        )
                }
                .padding(.bottom, 50)
            }
        }
    }
}
