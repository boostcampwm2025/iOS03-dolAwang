//
//  StandbyView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct StandbyView: View {
    let displayName: String

    var body: some View {
        VStack(spacing: 20) {
            Group {
                SpinningIndicatorView(isActive: true)

                Text("연결 대기 중...")
            }
            .font(.title.bold())
            .foregroundStyle(.primary.opacity(0.8))

            VStack(spacing: 12) {
                Text("아래의 이름을 iPhone에서 찾아주세요!")
                    .foregroundStyle(.primary.opacity(0.4))
                Text(displayName)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .foregroundStyle(.primary.opacity(0.6))
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.primary.opacity(0.3))
                    }
                    .padding(15)
            }
            .font(.headline)
        }
    }
}
