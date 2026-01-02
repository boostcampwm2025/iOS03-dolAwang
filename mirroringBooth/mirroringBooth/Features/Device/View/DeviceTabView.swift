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
    @Environment(MultipeerManager.self) var multipeerManager

    var body: some View {
        List {
            if multipeerManager.nearbyDevices.isEmpty {
                Text("주변 기기를 검색 중입니다..")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(multipeerManager.nearbyDevices) { device in
                    HStack {
                        // 기기 이름 (연결/해제)
                        Text(device.name)

                        Spacer()

                        Group {
                            // 연결 버튼
                            Button {
                                multipeerManager.connect(to: device)
                            } label: {
                                Image(systemName: "link")
                            }
                            .buttonStyle(.borderless)
                            .disabled(device.state != .notConnected)

                            // 연결 해제 버튼
                            Button {
                                multipeerManager.disconnect(from: device)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                            .disabled(device.state != .connected)
                        }
                        .padding(.vertical, 4)

                        // 상태 텍스트
                        Text(device.state.rawValue)
                            .font(.caption)
                            .foregroundStyle(stateColor(for: device.state))
                    }
                }
            }
    }
    .onAppear {
        if !multipeerManager.isSearching {
            multipeerManager.startSearching()
        }
    }
    // 탭 전환 시에도 연결 유지를 위해 stopSearching()을 호출하지 않습니다.
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
        .environment(MultipeerManager())
}

