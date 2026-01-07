//
//  BrowsingView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct BrowsingView: View {

    @Environment(Router.self) var router: Router
    @State private var store = BrowsingStore(Browser())

    var body: some View {
        ZStack {
            // 배경에 그려지는 2개의 원
            Circle()
                .foregroundStyle(Color(store.state.currentTarget.color).opacity(0.3))
                .frame(width: 180, height: 180)

            Circle()
                .foregroundStyle(Color(store.state.currentTarget.color).opacity(0.2))
                .frame(width: 260, height: 260)

            if store.state.isConnecting {
                ProgressView()
            }

            VStack(spacing: 15) {
                // 타겟 아이콘
                Image(systemName: store.state.currentTarget.icon)
                    .padding(15)
                    .font(.title.bold())
                    .foregroundStyle(Color(store.state.currentTarget.color))
                    .background(Color(store.state.currentTarget.color).opacity(0.2))
                    .clipShape(Capsule())

                // 타겟 설명
                Text(store.state.currentTarget.searchTitle)
                    .font(.title2)
                    .bold()

                Text(store.state.currentTarget.searchDescription)
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))

                // 발견된 기기 목록 (버튼)
                LazyVStack {
                    ScrollView {
                        ForEach(store.state.discoveredDevices, id: \.self) { device in
                            if device.type != .unknown {
                                Button {
                                    if !store.state.isConnecting {
                                        store.send(.didSelect(device))
                                    }
                                } label: {
                                    deviceRow(device)
                                }
                                .disabled(isDeviceSelected(device) != nil)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 5)

                // 취소 버튼
                if store.state.hasSelectedDevice || store.state.currentTarget == .remote {
                    Button {
                        store.send(.cancel)
                    } label: {
                        Text("처음부터 다시 연결하기")
                            .font(.footnote)
                            .foregroundStyle(Color.red)
                    }
                }

                // 다음 버튼
                if store.state.currentTarget == .remote {
                    Button {
                        if let mirroringDevice = store.state.mirroringDevice {
                            router.push(
                                to: CameraRoute.connectionList(
                                    ConnectionList(
                                        cameraName: store.browser.myDeviceName,
                                        mirroringName: mirroringDevice.id,
                                        remoteName: store.state.remoteDevice?.id ?? nil
                                    )
                                )
                            )
                        }
                    } label: {
                        Text(store.state.hasSelectedDevice ? "다음" : "건너뛰기")
                            .font(.callout)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
            .padding()
        }
        .onAppear {
            store.send(.entry)
        }
        .onDisappear {
            store.send(.exit)
        }
    }

    @ViewBuilder
    private func deviceRow(_ device: NearbyDevice) -> some View {
        let target = isDeviceSelected(device)

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
            if let target {
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
        .opacity(target != nil ? 0.5 : 1)
    }

    private func isDeviceSelected(_ device: NearbyDevice) -> DeviceUseType? {
        if store.state.mirroringDevice == device {
            return .mirroring
        } else if store.state.remoteDevice == device {
            return .remote
        }
        return nil
    }
}

#Preview {
    ContentView()
}
