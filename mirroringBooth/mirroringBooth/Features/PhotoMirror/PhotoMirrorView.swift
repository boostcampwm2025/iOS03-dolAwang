//
//  PhotoMirrorView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

enum PhotoReceiveState {
    case receiving
    case completed(UIImage)
    case failed
}

struct ReceivedPhoto: Identifiable {
    let id: UUID
    var state: PhotoReceiveState
}

/// 아이폰에서 촬영된 사진을 미러링 기기로 전송하는 기능을 구현합니다.
struct PhotoMirrorView: View {
    @Environment(MultipeerManager.self) var multipeerManager
    @State private var receivedPhotos: [ReceivedPhoto] = []

    var body: some View {
        Group {
            if multipeerManager.isVideoSender {
                // 아이폰일 경우
                senderView
            } else {
                // 아이패드나 mac일 경우
                receiverView
            }
        }
        .onAppear {
            setupPhotoReceiver()
        }
        .onDisappear {
            multipeerManager.onReceivingPhoto = nil
            multipeerManager.onReceivedPhotoResource = nil
            multipeerManager.onPhotoReceiveFailed = nil
        }
    }

    /// 아이폰용 안내 메시지
    private var senderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("아이패드/Mac 전용 탭입니다")
                .font(.headline)
            Text("이 탭은 수신 기기에서만 사용할 수 있습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// 아이패드/Mac용 이미지 리스트
    private var receiverView: some View {
        NavigationStack {
            if receivedPhotos.isEmpty {
                emptyView
            } else {
                imageGridView
            }
        }
    }

    /// 빈 상태 뷰
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("수신된 사진이 없습니다")
                .font(.headline)
            Text("아이폰에서 촬영한 사진이 여기에 표시됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// 이미지 그리드 뷰
    private var imageGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(receivedPhotos) { photo in
                    switch photo.state {
                    case .receiving:
                        HStack {
                            ProgressView()
                            Text("사진 수신 중...")
                        }
                        .frame(height: 150)

                    case .completed(let image):
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(8)

                    case .failed:
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("수신 실패")
                        }
                        .foregroundStyle(.red)
                        .frame(height: 150)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("수신된 사진")
    }

    /// 사진 수신 설정
    private func setupPhotoReceiver() {
        multipeerManager.onReceivingPhoto = { photoID in
            receivedPhotos.insert(
                ReceivedPhoto(id: photoID, state: .receiving),
                at: 0
            )
        }

        multipeerManager.onReceivedPhotoResource = { photoID, data in
            guard let image = UIImage(data: data) else { return }

            if let index = receivedPhotos.firstIndex(where: { $0.id == photoID }) {
                receivedPhotos[index].state = .completed(image)
            }
        }

        multipeerManager.onPhotoReceiveFailed = { photoID in
            if let index = receivedPhotos.firstIndex(where: { $0.id == photoID }) {
                receivedPhotos[index].state = .failed
            }
        }
    }
}

#Preview {
    PhotoMirrorView()
        .environment(MultipeerManager())
}

