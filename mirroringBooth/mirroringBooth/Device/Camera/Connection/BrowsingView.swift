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

    private enum Constants {
        enum Size {
            static let title: Font = .title.bold()
            static let iconCornerRadius: CGFloat = 15
        }

        enum Spacing {
            static let iconPadding: CGFloat = 10
        }
    }

    var body: some View {
        ZStack {
            // 배경에 그려지는 2개의 원
            Circle()
                .foregroundStyle(Color(store.state.currentTarget.color).opacity(0.3))
                .frame(width: 180, height: 180)

            Circle()
                .foregroundStyle(Color(store.state.currentTarget.color).opacity(0.2))
                .frame(width: 260, height: 260)

            VStack {
                // 타겟 아이콘
                Image(systemName: store.state.currentTarget.icon)
                    .padding(Constants.Spacing.iconPadding)
                    .font(Constants.Size.title)
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
                            Button {
                                if !store.state.isConnecting && !isDeviceSelected(device) {
                                    store.send(.didSelect(device))
                                }
                            } label: {
                                deviceRow(device)
                            }
                            .disabled(isDeviceSelected(device))
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 5)

                // 취소 버튼

                // 건너뛰기 버튼

                // 다음 버튼
                Button {
                    router.push(to: CameraRoute.connectionList)
                } label: {
                    Text("다음 단계")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color(.systemBackground))
                        .background(Color(.label))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            }
            .padding()
        }
        .onAppear {
            store.send(.entry)
        }
    }

    @ViewBuilder
    private func deviceRow(_ device: NearbyDevice) -> some View {
        let isSelected = isDeviceSelected(device)

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
            if isSelected {
                Image(systemName: store.state.currentTarget.icon)
                    .font(.title2)
                    .foregroundStyle(Color(store.state.currentTarget.color))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color(.label))
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isSelected ? 0.5 : 1)
    }

    private func isDeviceSelected(_ device: NearbyDevice) -> Bool {
        switch store.state.currentTarget {
        case .mirroring:
            return store.state.mirroringDevice == device
        case .remote:
            return store.state.remoteDevice == device
        }
    }
}

#Preview {
    ContentView()
}
