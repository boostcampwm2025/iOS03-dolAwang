//
//  ReceiverView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-24.
//

import SwiftUI

/// 스트림 수신 측 화면 (iPad/Mac)
/// 다른 기기로부터 스트림 데이터(비디오/사진)를 수신하여 표시
struct ReceiverView: View {

    @State private var receiver = StreamReceiver()
    @StateObject private var renderer = MediaFrameRenderer()
    @State private var packetHandler: PacketHandler?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            VStack {
                if !receiver.isConnected {
                    Text("연결을 시도해주세요...")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.top, 8)
                } else {
                    ZStack {
                        // 스트림 표시 (비디오 + 사진)
                        StreamDisplayView(renderer: renderer) {
                            // 촬영 버튼을 누르면 촬영 요청 패킷 전송
                            receiver.requestCapture()
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .navigationDestination(item: $photoData) { data in
                PhotoView(photoData: data)
            }
        }
        .onAppear {
            setupPacketHandler()
            receiver.startAdvertising()
        }
        .onDisappear {
            receiver.stopAdvertising()
            packetHandler?.cleanup()
        }
    }

    private func setupPacketHandler() {
        guard packetHandler == nil else { return }

        let videoDecoder = VideoDecoder()
        let handler = PacketHandler(videoDecoder: videoDecoder, renderer: renderer)

        handler.onPhotoReceived = { [self] data in
            photoData = data
        }

        receiver.onDataReceived = { data in
            handler.handlePacket(data)
        }

        packetHandler = handler
    }
}


#Preview {
    ReceiverView()
}
