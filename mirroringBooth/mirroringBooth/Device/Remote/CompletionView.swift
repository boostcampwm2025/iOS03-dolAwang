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
            Image(systemName: "checkmark.square")
                .font(.largeTitle)
                .foregroundStyle(Color.main)

            VStack(spacing: 5) {
                Text("촬영을 완료했습니다!")
                    .font(.title3.bold())
                Text("이 디바이스에서는 종료해도 괜찮습니다.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .opacity(0.8)

            Text("첫 화면으로 돌아가기")
                .padding(.top)
                .font(.footnote)
                .opacity(0.8)
                .onTapGesture {

                }
        }
        #if os(iOS)
        .backgroundStyle()
        #endif
    }
}
