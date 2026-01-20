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

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Text("연결 완료!")
                    .fontWeight(.heavy)
                    .font(.title)

                Text("촬영 준비를 완료해주세요")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(.darkGray))
            }
            Spacer()
        }
        .navigationBarBackButtonHidden()
        .backgroundStyle()
        .onAppear {
            advertiser.navigateToRemoteCaptureCallBack = {
                DispatchQueue.main.async {
                    router.push(to: RemoteRoute.remoteCapture(advertiser))
                }
            }
        }
        .onDisappear {
            advertiser.navigateToRemoteCaptureCallBack = nil
        }
    }
}
