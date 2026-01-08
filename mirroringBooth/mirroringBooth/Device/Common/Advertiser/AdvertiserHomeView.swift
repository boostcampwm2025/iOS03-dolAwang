//
//  AdvertiserHomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertiserHomeView: View {
    @Environment(Router.self) var router: Router
    @State private var store = AdvertiserHomeStore(Advertiser())

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            MainHeaderView()
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 중앙 상태 뷰
            if store.state.isAdvertising {
                StandbyView(displayName: store.advertiser.myDeviceName, isAdvertising: store.state.isAdvertising)
            } else {
                IdleView(displayName: store.advertiser.myDeviceName)
            }

            Spacer()

            // 하단 버튼
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.send(.didTapAdvertiseButton)
                }
            } label: {
                AdvertisingButton(isAdvertising: store.state.isAdvertising)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
        .onDisappear {
            store.send(.exit)
        }
        .onChange(of: store.state.hasConnectionStarted) { _, newValue in
            if newValue {
                router.push(to: MirroringRoute.modeSelection)
            }
        }
    }
}

// MARK: - Components

private struct AdvertisingButton: View {
    let isAdvertising: Bool

    var body: some View {
        let title: String = isAdvertising ? "검색 허용 중단" : "검색 가능 모드"

        let description: String = isAdvertising
        ? "다른 기기에서 검색 불가능한 상태로 전환합니다."
        : "다른 기기에서 검색 가능한 상태로 전환합니다."

        let icon: String = isAdvertising
        ? "antenna.radiowaves.left.and.right.slash"
        : "antenna.radiowaves.left.and.right"

        let color: Color = isAdvertising ? .red : .main

        VStack(spacing: 10) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.largeTitle.bold())
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))
            }
            .padding(12)
            .background(color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(description)
                .font(.footnote)
                .foregroundStyle(Color(.label).opacity(0.7))
        }
    }
}

private struct IdleView: View {
    let displayName: String

    var body: some View {
        VStack(spacing: 5) {
            Text("아직 검색 가능 모드가 아니에요")
                .font(.headline.weight(.heavy))

            HStack {
                Image(systemName: "scope")
                Text(displayName)
            }
            .font(.subheadline)

            Text("아래 버튼을 눌러 다른 기기에서 찾을 수 있게 해주세요.")
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
        }
        .foregroundStyle(Color(.darkGray))
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 1)
        )
    }
}

private struct StandbyView: View {
    let displayName: String
    let isAdvertising: Bool

    @State private var spin = false

    var body: some View {
        VStack(spacing: 6) {
            Group {
                Image(systemName: "arrow.2.circlepath")
                    .font(.title2)
                    .rotationEffect(.degrees(-45))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: spin
                    )
                    .onAppear {
                        // "상태 변화"를 만들어 repeatForever 트리거
                        if isAdvertising { spin = true }
                    }
                    .onChange(of: isAdvertising) { _, newValue in
                        spin = newValue
                    }

                Text("연결 대기 중...")
                    .fontWeight(.heavy)
            }
            .foregroundStyle(Color(.lightGray))

            Text("\(displayName)으로 검색되는 중입니다.")
                .font(.caption2.bold())
                .foregroundStyle(Color(.darkGray))
        }
    }
}

// 작업 이전 뷰라서 Preview를 제거하지 않은 상태입니다
#Preview {
    AdvertiserHomeView()
}
