//
//  DeviceStatusBadge.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/7/26.
//

import SwiftUI

/// 디바이스 연결 상태
struct DeviceStatusBadge: View {
    let deviceName: String
    let batteryLevel: Int
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(deviceName)
                .fontWeight(.medium)

            Divider()
                .frame(height: 14)

            HStack(spacing: 4) {
                Image(systemName: batterySymbol)
                Text("\(batteryLevel)%")
                Image(systemName: wifiSymbol)
            }
            .font(.caption)
            .foregroundStyle(batteryColor)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.black.opacity(0.5))
        )
    }
}

private extension DeviceStatusBadge {
    /// Wi-Fi 상태 아이콘
    var wifiSymbol: String {
        isConnected ? "wifi" : "wifi.slash"
    }

    /// 배터리 아이콘
    var batterySymbol: String {
        switch batteryLevel {
        case 75...100:
            return "battery.100percent"
        case 50..<75:
            return "battery.75percent"
        case 25..<50:
            return "battery.50percent"
        case 15..<25:
            return "battery.25percent"
        default:
            return "battery.0percent"
        }
    }

    /// 배터리 상태 색상
    var batteryColor: Color {
        switch batteryLevel {
        case 75...100:
            return .green
        case 50..<75:
            return .orange
        case 25..<50:
            return .orange
        default:
            return .red
        }
    }
}
