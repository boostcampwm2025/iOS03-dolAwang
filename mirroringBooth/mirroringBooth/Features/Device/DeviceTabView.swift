//
//  DeviceTabView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 12/28/25.
//

import SwiftUI

// 주변의 애플 기기를 탐색하는 기능을 구현합니다.
// 선택한 애플 기기와의 통신 연결 상태를 확인합니다.
struct DeviceTabView: View {
    @State private var multipeerManager = MultipeerManager()

    var body: some View {
        List {
            if multipeerManager.nearbyDevices.isEmpty {
                Text("주변 기기를 검색 중입니다..")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(multipeerManager.nearbyDevices) { device in
                    HStack {
                        Button {
                            multipeerManager.connect(to: device)
                        } label: {
                            Text(device.name)
                        }
                        // 연결 중이거나 연결된 기기는 버튼을 비활성화합니다.
                        .disabled(device.state == .connecting || device.state == .connected)

                        Spacer()

                        // 테스트 메세지 전송 버튼
                        Button {
                            multipeerManager.sendMessage(to: device)
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .disabled(device.state != .connected)

                        // 연결 상태 텍스트
                        Text(device.state.rawValue)
                            .font(.caption)
                            .foregroundStyle(stateColor(for: device.state))
                    }
                }
            }
        }
        .onAppear {
            multipeerManager.startSearching()
        }
        .onDisappear {
            multipeerManager.stopSearching()
        }
    }

    private func stateColor(for state: ConnectionState) -> Color {
        switch state {
        case .notConnected: .secondary
        case .connecting: .orange
        case .connected: .green
        }
    }
}

#Preview {
    DeviceTabView()
}

