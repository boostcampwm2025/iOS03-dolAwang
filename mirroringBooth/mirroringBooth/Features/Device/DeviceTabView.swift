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
                    Button {
                        multipeerManager.connect(to: device)
                    } label: {
                        HStack {
                            Text(device.name)
                            Spacer()
                            Text(device.state.rawValue)
                                .font(.caption)
                                .foregroundStyle(stateColor(for: device.state))
                        }
                    }
                    // 연결 중이거나 연결된 기기는 버튼을 비활성화합니다.
                    .disabled(device.state == .connecting || device.state == .connected)
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

