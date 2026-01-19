//
//  DisconnectButtonView.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

struct DisconnectButtonView: View {
    let textFont: Font
    let backgroundColor: Color
    let action: () -> Void

    init(textFont: Font = .callout, backgroundColor: Color = .borderLine, action: @escaping () -> Void) {
        self.textFont = textFont
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("연결 끊기")
            }
            .font(textFont)
            .foregroundColor(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(backgroundColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
        .padding(.horizontal, 20)
    }
}
