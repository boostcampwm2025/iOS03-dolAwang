//
//  ConfirmationAlert.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-19.
//

import SwiftUI

struct ConfirmationAlert: View {
    let message: String
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?

    init(
        message: String,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)?
    ) {
        self.message = message
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel?()
                }

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)

                    Text("주의")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary.opacity(0.8))
                }

                HStack(spacing: 16) {
                    if onCancel != nil {
                        Button {
                            onCancel?()
                        } label: {
                            Text("계속하기")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.gray.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    Button {
                        onConfirm()
                    } label: {
                        Text("나가기")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .font(.headline)
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6).opacity(0.8))
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 40)
        }
    }
}

extension View {
    func homeAlert(
        isPresented: Binding<Bool>,
        message: String = "진행 중인 작업이 사라질 수 있습니다.\n정말 나가시겠습니까?",
        cancellable: Bool = true,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                ConfirmationAlert(
                    message: message,
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    },
                    onCancel: !cancellable ? nil : {
                        isPresented.wrappedValue = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeOut(duration: 0.2), value: isPresented.wrappedValue)
            }
        }
    }
}
