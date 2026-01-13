//
//  BrowserReconnectionView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/13/26.
//

import SwiftUI

struct BrowserReconnectionView: View {
    let reconnectionType: ReconnectionType
    let store: BrowsingStore

    var body: some View {
        ZStack {
            SearchingBackground(
                color: store.state.hasSelectedDevice ? .green : .red
            )

            if store.state.isConnecting {
                ProgressView()
            }

            VStack(spacing: 15) {
                VStack(spacing: 8) {
                    Image(systemName: reconnectionType.icon)
                        .padding(15)
                        .font(.title.bold())
                        .foregroundStyle(store.state.hasSelectedDevice ? .green : .red)
                        .background((store.state.hasSelectedDevice ? Color.green : Color.red).opacity(0.2))
                        .clipShape(Capsule())

                    Text("연결이 끊어졌습니다")
                        .font(.title2)
                        .bold()

                    Text(reconnectionType.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    LazyVStack {
                        ForEach(store.state.discoveredDevices) { device in
                            if device.type != .unknown {
                                Button {
                                    if !store.state.isConnecting {
                                        store.send(.didSelect(device))
                                    }
                                } label: {
                                    DeviceRow(
                                        device: device,
                                        selectedTarget: isDeviceSelected(device)
                                    )
                                }
                                .disabled(isDeviceSelected(device) != nil || store.state.isConnecting)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 5)

                if store.state.hasSelectedDevice {
                    Button {
                        // 재연결 로직
                    } label: {
                        Text("재연결")
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

    private var selectedDevice: NearbyDevice? {
        switch store.state.currentTarget {
        case .mirroring:
            store.state.mirroringDevice
        case .remote:
            store.state.remoteDevice
        }
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

// UI 테스트를 위한 프리뷰입니다.
#Preview {
    BrowserReconnectionView(reconnectionType: .both, store: BrowsingStore(Browser()))
}
