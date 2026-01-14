//
//  StandbyView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct StandbyView: View {
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
