//
//  AdvertiserHomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertiserHomeView: View {
    @State var advertiser = Advertiser()

    var body: some View {
        Text("미러링/리모트 기기의 시작 화면")
            .onAppear {
                advertiser.startSearching()
            }
    }
}

// 작업 이전 뷰라서 Preview를 제거하지 않은 상태입니다
#Preview {
    AdvertiserHomeView()
}
