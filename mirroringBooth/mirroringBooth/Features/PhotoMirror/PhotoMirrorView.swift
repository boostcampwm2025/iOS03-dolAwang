//
//  PhotoMirrorView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

/// 아이폰에서 촬영된 사진을 미러링 기기로 전송하는 기능을 구현합니다.
struct PhotoMirrorView: View {
    @Environment(MultipeerManager.self) var multipeerManager

    var receivedPhotos: [ReceivedPhoto] {
        multipeerManager.receivedPhotos
    }

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

                    case .receiving(let progress):
                        VStack(spacing: 8) {
                            ProgressView(value: progress)
                            Text("사진 수신 중… \(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                        VStack(spacing: 8) {
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
}

#Preview {
    PhotoMirrorView()
        .environment(MultipeerManager())
}
