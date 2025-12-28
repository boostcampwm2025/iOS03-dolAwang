//
//  AdvertiserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

/// 비디오 수신 측 화면 (iPad/Mac)
/// 다른 기기로부터 H.264 비디오 스트림을 수신하여 재생
struct AdvertiserView: View {

    private var receiver = VideoReceiver()
    /// H.264 디코더 - 수신된 비디오 패킷을 디코딩
    private let videoDecoder = VideoDecoder()

    var body: some View {
        VStack {
            if !receiver.connectionState {
                Text("연결을 시도해주세요...")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(.top, 8)
            } else {
                ZStack {
                    // 비디오 스트림 표시
                    ScreenView(decoder: videoDecoder)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            // 비디오 수신 콜백 설정
            receiver.onVideoReceived = { data in
                videoDecoder.handleReceivedPacket(data)
            }
            receiver.startAdvertising()
        }
        .onDisappear {
            receiver.stopAdvertising()
            videoDecoder.cleanup()
        }
    }
}

#Preview {
    AdvertiserView()
}
