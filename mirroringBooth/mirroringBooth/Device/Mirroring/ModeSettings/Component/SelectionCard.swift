//
//  SelectionCard.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-27.
//

import SwiftUI

struct SelectionCard: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void
    @State private var descriptionTruncated: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 24) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(iconColor)
                    .overlay(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                    )
                    .padding(25)
                    .padding(.top)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    if !descriptionTruncated {
                        DescriptionLabel(description: description)
                            .modifier(
                                TruncationDetectionModifier(
                                    text: description,
                                    lineLimit: 2,
                                    isTruncated: $descriptionTruncated
                                )
                            )
                    }
                }
                .padding(.bottom)
            }
            .frame(maxWidth: 400, maxHeight: 350)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.cardComponent)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.borderLine, lineWidth: 3)
            )
            .padding()
        }
        .buttonStyle(.plain)
    }
}

private struct DescriptionLabel: View {
    let description: String

    var body: some View {
        Text(description)
            .font(.subheadline)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

private struct TruncationDetectionModifier: ViewModifier {
    let text: String
    let lineLimit: Int
    @Binding var isTruncated: Bool

    func body(content: Content) -> some View {
        content
            .lineLimit(lineLimit)
            .background(
                GeometryReader { proxy in
                    DescriptionLabel(description: text)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0)
                        .background(
                            GeometryReader { fullTextProxy in
                                Color.clear.onAppear {
                                    isTruncated = fullTextProxy.size.height > proxy.size.height
                                }
                                .onChange(of: proxy.size.height) {
                                    isTruncated = fullTextProxy.size.height > proxy.size.height
                                }
                                .onChange(of: fullTextProxy.size.height) {
                                     isTruncated = fullTextProxy.size.height > proxy.size.height
                                }
                            }
                        )
                }
            )
    }
}
