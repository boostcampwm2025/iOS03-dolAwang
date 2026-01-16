//
//  IdleView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct IdleView: View {
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
