//
//  StreamingCompletionView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

struct StreamingCompletionView: View {
    @Environment(Router.self) var router: Router

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // TODO: #26 병합 후 HomeButton 추가
                Image(systemName: "photo.badge.checkmark")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.main)
                VStack(spacing: 5) {
                    Text("촬영이 완료되었습니다!")
                        .font(.title2.bold())
                    Text("미러링 기기에서 편집을 진행해주세요.")
                        .font(.subheadline.bold())
                        .opacity(0.7)
                }
                Text("편집이 완료된 사진을 이 디바이스에 저장하고 싶다면\n이 화면에서 대기해주세요.")
                    .font(.footnote)
                    .opacity(0.7)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
