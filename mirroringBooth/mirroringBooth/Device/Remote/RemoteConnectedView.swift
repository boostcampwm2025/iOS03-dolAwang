//
//  RemoteConnectedView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/20/26.
//

import SwiftUI

struct RemoteConnectedView: View {
    @Environment(Router.self) var router: Router
    let advertiser: Advertiser

    @State private var showCheckmark = false

    var body: some View {
        ConnectedView(description: "미러링 기기에서 촬영 방식을 선택해주세요")
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
        }
    }
}
