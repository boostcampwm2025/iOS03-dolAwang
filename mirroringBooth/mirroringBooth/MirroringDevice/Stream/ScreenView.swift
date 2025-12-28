//
//  ScreenView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import SwiftUI

/// 디코딩된 비디오 프레임을 화면에 렌더링하는 뷰
struct ScreenView: View {

    @StateObject private var viewModel: ScreenViewModel

    init(decoder: VideoDecoder) {
        _viewModel = StateObject(wrappedValue: ScreenViewModel(decoder: decoder))
    }

    var body: some View {
        GeometryReader { geometry in
            if let image = viewModel.currentFrame {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color.black)
    }
}
