//
//  Toast+.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/22/26.
//

import SwiftUI

extension View {
    func toast(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 2,
        message: String
    ) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastOverlayView(
                    isPresented: isPresented,
                    duration: duration,
                    message: message
                )
                .padding(.horizontal, 12)
        }
    }
}

private struct ToastOverlayView: View {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let message: String

    @State private var yOffset: CGFloat = 0
    @State private var opacityValue: Double = 0
    @State private var dismissWorkItem: DispatchWorkItem?

    var body: some View {
        if isPresented {
            ToastCardView(message)
                .offset(y: yOffset)
                .opacity(opacityValue)
                .onAppear {
                    presentAnimated()
                    scheduleDismiss()
                }
                .onDisappear {
                    dismissWorkItem?.cancel()
                    dismissWorkItem = nil
                }
                .transition(.identity)
        }
    }

    private func presentAnimated() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 0.0)) {
            yOffset = -100
            opacityValue = 1
        }
    }

    private func scheduleDismiss() {
        let workItem = DispatchWorkItem {
            dismissAnimated()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func dismissAnimated() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            yOffset = 0
            opacityValue = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

private struct ToastCardView: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.caption)
            .lineLimit(3)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray5).opacity(0.5))
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: Color(.systemGray2).opacity(0.5), radius: 18, x: 0, y: 10)
    }
}
