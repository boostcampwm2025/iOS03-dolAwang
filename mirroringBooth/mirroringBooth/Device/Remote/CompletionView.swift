//
//  CompletionView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 10) {
            // TODO: #26 병합 후 홈 버튼 추가
            Image(systemName: "checkmark.square")
                .font(.largeTitle)
                .foregroundStyle(Color.main)

            Text("촬영을 완료했습니다!")
                .font(.title3.bold())
                .opacity(0.8)
        }
    }
}

#Preview {
    CompletionView()
}
