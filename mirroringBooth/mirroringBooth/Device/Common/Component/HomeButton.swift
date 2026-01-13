//
//  HomeButton.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

struct HomeButton: View {
    private let size: Font
    private var action: () -> Void

    init(
        size: Font,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "house")
                .foregroundStyle(Color(.label))
                .bold()
                .padding(5)
                .background {
                    Circle()
                        .stroke(Color(.label), lineWidth: 2)
                }
        }
    }
}
