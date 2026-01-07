//
//  AdvertisierHomeView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-07.
//

import SwiftUI

struct AdvertisierHomeView: View {
    @State var advertisier = Advertisier()

    var body: some View {
        Text("미러링/리모트 기기의 시작 화면")
            .onAppear {
                advertisier.startSearching()
            }
    }
}

#Preview {
    AdvertisierHomeView()
}
