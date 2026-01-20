//
//  BrowsingView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct BrowsingView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) var rootStore: RootStore
    @State private var store = BrowsingStore(Browser(), WatchConnectionManager())

    var body: some View {
        ZStack {
            AnimatedCircle(
                color: Color(store.state.currentTarget.color),
                animationTrigger: store.state.animationTrigger
            )

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
                                .disabled(isDeviceDisabled(device))
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
                                    ),
                                    store.browser
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
            if rootStore.browser == nil {
                rootStore.browser = store.browser
            }
            store.browser.onHeartbeatTimeout = {
                rootStore.send(.showTimeoutAlert(true))
            }
        }
        .onDisappear {
            store.send(.exit)
        }
        .onChange(of: scenePhase) { _, newValue in
            let state: UIApplication.State
            switch newValue {
            case .active: state = .active
            case .background: state = .background
            default: state = .inactive
            }
            store.send(.didChangeAppState(state))
        }
        .backgroundStyle()
    }

    private func isDeviceSelected(_ device: NearbyDevice) -> DeviceUseType? {
        if store.state.mirroringDevice == device {
            return .mirroring
        } else if store.state.remoteDevice == device {
            return .remote
        }
        return nil
    }

    private func isDeviceDisabled(_ device: NearbyDevice) -> Bool {
        return isDeviceSelected(device) != nil ||
        (store.state.currentTarget == .mirroring && device.type == .watch)
    }
}
