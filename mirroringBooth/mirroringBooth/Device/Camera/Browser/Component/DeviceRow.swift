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

    var body: some View {
        HStack {
            Image(systemName: device.type.icon)
                .font(.title)

            VStack(alignment: .leading) {
                Text(device.id)
                    .font(.headline.bold())
                Text(device.type.rawValue)
                    .font(.footnote)
            }

            Spacer()

            // 선택된 기기인 경우 상징적인 아이콘 표시
            if let target = selectedTarget {
                Image(systemName: target.icon)
                    .font(.title2)
                    .foregroundStyle(Color(target.color))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color(.label))
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(selectedTarget != nil ? 0.5 : 1)
    }
}
