//
//  VideoStreamReceiverView.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/2/26.
//

import SwiftUI

/// iPad나 Mac에 수신된 비디오 스트림을 표시하는 View
struct VideoStreamReceiverView: View {
    @Environment(MultipeerManager.self) var multipeerManager

    var body: some View {
        ZStack {
            Text("수신된 스트림이 여기에 표시됩니다")
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    VideoStreamReceiverView()
        .environment(MultipeerManager())
}

