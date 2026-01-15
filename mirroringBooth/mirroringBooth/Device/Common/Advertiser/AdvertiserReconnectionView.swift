//
//  AdvertiserReconnectionView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct AdvertiserReconnectionView: View {
    let store: AdvertiserHomeStore
    let onMoveToHome: () -> Void

    @State private var isRotating = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .padding(15)
                .font(.title.bold())
                .foregroundStyle(.red)
                .background(.red.opacity(0.2))
                .clipShape(Capsule())
            Text("촬영 기기와의 연결이 끊어졌습니다.")
                .font(.title2.bold())
            Group {
                Text("재연결을 시도합니다.")
                    .font(.footnote)

                SpinningIndicatorView(isActive: true)
            }
            .foregroundStyle(Color(.secondaryLabel))

            Button {
                store.reduce(.setIsReconnectRequired(false))
                onMoveToHome()
            } label: {
                Text("첫 화면으로 돌아가기")
                    .font(.footnote)
                    .foregroundStyle(Color(.label))
                    .opacity(0.8)
            }
        }
        .padding(16)
    }
}
