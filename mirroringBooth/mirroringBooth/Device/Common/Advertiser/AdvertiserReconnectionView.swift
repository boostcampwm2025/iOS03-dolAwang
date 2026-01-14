//
//  AdvertiserReconnectionView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct AdvertiserReconnectionView: View {
    let store: AdvertiserHomeStore

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .padding(15)
                    .font(.title.bold())
                    .foregroundStyle(.red)
                    .background(.red.opacity(0.2))
                    .clipShape(Capsule())
                Text("촬영 기기와의 연결이 끊어졌습니다.")
                    .font(.title2.bold())
                Text("다시 연결해주세요.")
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            if store.state.isAdvertising {
                StandbyView(
                    displayName: store.advertiser.myDeviceName,
                    isAdvertising: store.state.isAdvertising
                )
            } else {
                IdleView(displayName: store.advertiser.myDeviceName)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.send(.didTapAdvertiseButton)
                }
            } label: {
                AdvertisingButton(isAdvertising: store.state.isAdvertising)
            }
        }
        .onAppear {
            store.send(.didTapAdvertiseButton)
        }
        .onDisappear {
            store.send(.exit)
        }
        .padding(16)
    }
}
