//
//  BrowsingReconnectionView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/13/26.
//

import SwiftUI

struct BrowsingReconnectionView: View {
    let reconnectionType: ReconnectionType
    let store: BrowsingStore

    private var isAllConnected: Bool {
        switch reconnectionType {
        case .both:
            let mirroring = store.state.mirroringDevice
            let remote = store.state.remoteDevice
            return mirroring != nil && remote != nil
        case .mirroringOnly:
            return store.state.mirroringDevice != nil
        case .remoteOnly:
            return store.state.remoteDevice != nil
        }
    }

    var body: some View {
        ZStack {
            SearchingBackground(color: isAllConnected ? .green : .red)

            if store.state.isConnecting {
                ProgressView()
            }

            VStack(spacing: 15) {
                VStack(spacing: 8) {
                    Image(systemName: reconnectionType.icon)
                        .padding(15)
                        .font(.title.bold())
                        .foregroundStyle(isAllConnected ? .green : .red)
                        .background((isAllConnected ? Color.green : Color.red).opacity(0.2))
                        .clipShape(Capsule())

                    Text(reconnectionType.title)
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
            }
            .padding()
        }
        .onAppear {
            if let firstTarget = reconnectionType.targetTypes.first {
                store.state.currentTarget = firstTarget
            }
            store.send(.entry)
        }
        .onDisappear {
            store.send(.exit)
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