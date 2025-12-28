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
                Text(multipeerManager.isSearching ? "주변 기기를 검색 중입니다.." : "기기 검색을 시작해주세요.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(
                    Array(multipeerManager.nearbyDevices),
                    id: \.self
                ) { device in
                    Text(device.name)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                multipeerManager.toggleSearching()
            } label: {
                Text(multipeerManager.isSearching ? "검색 종료" : "검색 시작")
                    .frame(maxWidth: 200)
            }
            .padding(.bottom, 12)
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    DeviceTabView()
}
