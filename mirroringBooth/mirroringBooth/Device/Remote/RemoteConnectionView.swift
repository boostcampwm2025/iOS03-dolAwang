//
//  RemoteConnectionView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/20/26.
//

import SwiftUI

struct RemoteConnectionView: View {
    @Environment(Router.self) var router: Router
    let advertiser: Advertiser

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color("remoteColor"))
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
            }
            .padding(.bottom, 10)

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("연결 완료!")
                        .fontWeight(.heavy)
                        .font(.title)

                    Text("미러링 기기에서 촬영 방식을 선택해주세요")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 40)
                }
            }
            Spacer()
        }
        .backgroundStyle()
        .onAppear {
            // 리모트 모드 선택 시 촬영 뷰로 이동
            advertiser.navigateToRemoteCaptureCallBack = { [weak router] in
                guard let router else { return }
                DispatchQueue.main.async {
                    router.push(to: RemoteRoute.remoteCapture(advertiser))
                }
            }

            // 타이머 모드 선택 시 처음 화면으로 이동
            advertiser.navigateToHomeCallback = { [weak router] in
                guard let router else { return }
                DispatchQueue.main.async {
                    router.reset()
                }
            }

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }
        }
        .onDisappear {
            advertiser.navigateToRemoteCaptureCallBack = nil
            advertiser.navigateToHomeCallback = nil
        }
    }
}
