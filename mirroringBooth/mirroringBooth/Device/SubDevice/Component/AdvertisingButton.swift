//
//  AdvertisingButton.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/14/26.
//

import SwiftUI

struct AdvertisingButton: View {
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
