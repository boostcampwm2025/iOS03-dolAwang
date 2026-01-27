//
//  CountdownOverlay.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

// 카운트다운 오버레이
struct CountdownOverlay: View {
    let value: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            Text("\(value)초 뒤에 사진을 촬영합니다!")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
