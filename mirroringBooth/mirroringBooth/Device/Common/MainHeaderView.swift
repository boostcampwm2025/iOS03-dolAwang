//
//  MainHeaderView.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-08.
//

import SwiftUI

struct MainHeaderView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text("가장 선명하게,")
                Text("우리다운 순간을")
                    .foregroundStyle(Color.main)
                Text("기록하다.")
            }
            .font(.title.bold())

            Text("Mirroring Booth")
                .font(.caption.bold())
                .foregroundStyle(Color(.secondaryLabel))
        }
    }
}
