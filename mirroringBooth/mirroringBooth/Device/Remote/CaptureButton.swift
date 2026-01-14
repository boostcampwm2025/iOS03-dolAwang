//
//  CaptureButton.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/8/26.
//

import SwiftUI

struct CaptureButton: View {
    private let width: CGFloat
    var action: () -> Void

    init(
        width: CGFloat,
        action: @escaping () -> Void
    ) {
        self.width = width
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .stroke(darkGrayContainer, lineWidth: 0.5)
                Image(systemName: "camera")
                    .font(.title2)
                    .foregroundStyle(darkGrayContainer)
                    .bold()
            }
            .frame(width: width / 2)
            .background {
                Circle()
                    .frame(width: width / 2 * 1.1, height: width / 2 * 1.1)
            }
        }
        .buttonStyle(.plain)
    }

    let lightGrayontainer = Color(#colorLiteral(red: 0.422652036, green: 0.4431175292, blue: 0.5056651235, alpha: 1)) // #6d7180
    let darkGrayContainer = Color(#colorLiteral(red: 0.1215686275, green: 0.1607843137, blue: 0.2156862745, alpha: 1)) // #1f2937
    let green400 = Color(#colorLiteral(red: 0.2901960784, green: 0.8705882353, blue: 0.5019607843, alpha: 1)) // #4ade80
}
