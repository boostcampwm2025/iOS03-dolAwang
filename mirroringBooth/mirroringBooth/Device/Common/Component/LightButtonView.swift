//
//  LightButtonView.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

struct LightButtonView: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "sun.max")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .padding(10)
                .background(
                    Circle()
                        .foregroundStyle(Color.borderLine)
                )
        }
    }
}
