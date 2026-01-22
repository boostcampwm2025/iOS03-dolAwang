//
//  ConnectedView.swift
//  mirroringBooth
//
//  Created by Liam on 1/22/26.
//

import SwiftUI

struct ConnectedView: View {
    let description: String
    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color("remoteColor"))
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
            }
            .padding(.bottom, 10)

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("연결 완료!")
                        .fontWeight(.heavy)
                        .font(.title)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 40)
                }
            }
            Spacer()
        }
        .backgroundStyle()
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }
        }
    }
}
