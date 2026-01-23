//
//  StreamingCompletionView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

struct StreamingCompletionView: View {
    @Environment(Router.self) var router: Router
    @Environment(RootStore.self) private var rootStore
    @State private var showHomeAlert: Bool = false

    var body: some View {
        VStack {
            DisconnectButtonView {
                showHomeAlert = true
            }

            Spacer()
            VStack(spacing: 10) {
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
            }
            Spacer()
        }
        .navigationBarBackButtonHidden()
        .backgroundStyle()
        .homeAlert(
            isPresented: $showHomeAlert,
            message: "연결을 종료하시겠습니까?"
        ) {
            router.reset()
            rootStore.send(.disconnect)
        }
    }
}
