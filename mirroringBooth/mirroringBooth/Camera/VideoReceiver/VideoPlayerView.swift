//
//  VideoPlayerView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import SwiftUI

/// 디코딩된 비디오 프레임을 화면에 렌더링하는 뷰
struct VideoPlayerView: View {

    @StateObject private var viewModel: VideoPlayerViewModel

    init(decoder: VideoDecoder) {
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(decoder: decoder))
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
