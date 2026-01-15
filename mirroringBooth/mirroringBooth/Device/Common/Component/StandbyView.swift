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

    var body: some View {
        VStack(spacing: 6) {
            Group {
                SpinningIndicatorView(isActive: isAdvertising)

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
