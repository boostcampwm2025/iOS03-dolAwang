//
//  DeviceRow.swift
//  mirroringBooth
//
//  Created by 윤대현 on 2026-01-13.
//

import SwiftUI

struct DeviceRow: View {
    let device: NearbyDevice
    let selectedTarget: DeviceUseType?
    let iconFrameWidth: CGFloat

    init(
        device: NearbyDevice,
        selectedTarget: DeviceUseType?,
        iconFrameWidth: CGFloat = 32
    ) {
        self.device = device
        self.selectedTarget = selectedTarget
        self.iconFrameWidth = iconFrameWidth
    }

    // 좌측 기기 아이콘 색상
    private var iconColor: Color {
        if let target = selectedTarget {
            return Color(target.color)
        }
        return Color(.label)
    }

    // 테두리 색상
    private var borderColor: Color {
        if let target = selectedTarget {
            return Color(target.color)
        }
        return Color.clear
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: device.type.icon)
                .font(.title)
                .foregroundStyle(iconColor)
                .frame(width: iconFrameWidth, alignment: .center)
                .padding(.trailing, 16)

            VStack(alignment: .leading) {
                Text(device.id.replacingOccurrences(of: "(", with: "\n("))
                    .multilineTextAlignment(.leading)
                    .font(.headline.bold())
                Text(device.type.rawValue)
                    .font(.footnote)
            }

            Spacer(minLength: 8)

            // 선택된 기기인 경우 상징적인 아이콘 표시
            Image(systemName: selectedTarget?.icon ?? "multiply")
                .font(.title2)
                .foregroundStyle(borderColor)
                .frame(width: iconFrameWidth, alignment: .center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color(.label))
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        }
    }
}
