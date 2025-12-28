//
//  StreamDisplayView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import SwiftUI

/// 디코딩된 비디오 프레임을 화면에 렌더링하는 뷰
struct StreamDisplayView: View {

    @ObservedObject private var viewModel: StreamDisplayViewModel
    var onCaptureRequested: (() -> Void)?

    init(viewModel: StreamDisplayViewModel, onCaptureRequested: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCaptureRequested = onCaptureRequested
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if let image = viewModel.currentFrame {
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
                    onCaptureRequested?()
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
