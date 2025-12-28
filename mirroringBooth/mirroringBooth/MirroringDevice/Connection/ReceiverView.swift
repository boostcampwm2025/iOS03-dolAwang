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
    @StateObject private var viewModel = StreamDisplayViewModel()
    @State private var router: PacketRouter?
    @State private var isShowingPhoto = false

    init() {
        // router는 onAppear에서 초기화
    }

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
                        StreamDisplayView(viewModel: viewModel) {
                            // 촬영 버튼을 누르면 촬영 요청 패킷 전송
                            receiver.requestCapture()
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingPhoto) {
                if let photo = viewModel.capturedPhoto {
                    PhotoView(photo: photo)
                }
            }
            .onChange(of: viewModel.capturedPhoto) { oldValue, newValue in
                if newValue != nil {
                    isShowingPhoto = true
                }
            }
            .onChange(of: isShowingPhoto) { oldValue, newValue in
                if !newValue {
                    viewModel.capturedPhoto = nil
                }
            }
        }
        .onAppear {
            // router 초기화 및 콜백 설정
            if router == nil {
                let videoDecoder = VideoDecoder()
                let newRouter = PacketRouter(videoDecoder: videoDecoder, viewModel: viewModel)
                router = newRouter

                // 수신된 데이터를 라우터로 전달
                receiver.onDataReceived = { data in
                    newRouter.routePacket(data)
                }
            }

            receiver.startAdvertising()
        }
        .onDisappear {
            receiver.stopAdvertising()
            router?.cleanup()
        }
    }
}


#Preview {
    ReceiverView()
}
