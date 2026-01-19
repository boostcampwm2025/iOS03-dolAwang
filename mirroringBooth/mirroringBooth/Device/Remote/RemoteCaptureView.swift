//
//  RemoteConnectionTestView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/16/26.
//

import SwiftUI

struct RemoteCaptureView: View {
    @Environment(Router.self) var router: Router
    let advertiser: Advertiser

    var body: some View {
        GeometryReader { geometry in
            let buttonSize = min(geometry.size.width, geometry.size.height) * 0.3
            CaptureButton(width: buttonSize) {
                advertiser.sendCommand(.capturePhoto)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .backgroundStyle()
        .onAppear {
            advertiser.navigateToRemoteCompleteCallBack = {
                router.push(to: RemoteRoute.completion)
            }
        }
    }
}
