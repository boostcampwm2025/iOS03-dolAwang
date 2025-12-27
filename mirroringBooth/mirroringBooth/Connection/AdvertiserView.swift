//
//  AdvertiserView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

struct AdvertiserView: View {
    
    private var connectionManager: Advertiser
    private let videoDecoder = VideoDecoder()

    init(_ connectionManager: Advertiser) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        VStack {
            if connectionManager.connectionState.isEmpty {
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
                    VideoPlayerView(decoder: videoDecoder)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            // 비디오 수신 콜백 설정
            connectionManager.onVideoReceived = { data in
                videoDecoder.handleReceivedPacket(data)
            }
            connectionManager.startAdvertising()
        }
        .onDisappear {
            connectionManager.stopAdvertising()
            videoDecoder.cleanup()
        }
    }
}

#Preview {
    AdvertiserView(ConnectionManager())
}
