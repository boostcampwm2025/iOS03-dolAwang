//
//  CaptureButton.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/8/26.
//

import Combine
import SwiftUI

struct CaptureButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var cancellable: AnyCancellable?
    @State private var tapSubject: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>()
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
            tapSubject.send(())
        } label: {
            ZStack {
                Circle()
                    .stroke(
                        Color("TextPrimary").opacity(0.8),
                        lineWidth: 1
                    )
                    .frame(width: width / 2)

                Circle()
                    .stroke(
                        Color("buttonComponent").opacity(colorScheme == .dark ? 0.7 : 0.5),
                        lineWidth: colorScheme == .dark ? 0.5 : 1
                    )
                    .frame(width: width / 2 * (colorScheme == .dark ? 1 : 0.85))

                Image(systemName: "camera.fill")
                    .font(.title.bold())
                    .foregroundStyle(Color.black)
            }
            .frame(width: width / 2)
            .background {
                Circle()
                    .fill(colorScheme == .dark ? Color.white : Color.clear)
                    .frame(width: width / 2 * 1.1, height: width / 2 * 1.1)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if cancellable != nil { return }

            cancellable = tapSubject
                .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: false)
                .sink {
                    action()
                }
        }
        .onDisappear {
            cancellable?.cancel()
            cancellable = nil
        }
    }
}
