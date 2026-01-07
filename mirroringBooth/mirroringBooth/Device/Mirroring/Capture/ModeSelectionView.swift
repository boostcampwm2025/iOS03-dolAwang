//
//  ModeSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/6/26.
//

import SwiftUI

struct ModeSelectionView: View {
    var timerCard: some View {
        SelectionCard(
            iconName: "stopwatch",
            iconColor: Color.timerIcon,
            title: "타이머 모드",
            description: "60초 동안 5초 간격으로\n자동 촬영합니다."
        ) {
            // action
        }
    }

    var remoteCard: some View {
        SelectionCard(
            iconName: "applewatch", // SF Symbol
            iconColor: Color.watchIcon,
            title: "리모콘 모드",
            description: "나의 Apple Watch에서 \n직접 셔터를 누르세요."
        ) {
            // action
        }
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                TopBarView()

                Spacer()

                TitleView()

                GeometryReader { proxy in
                    if proxy.size.width > proxy.size.height {
                        HStack(spacing: 40) {
                            timerCard
                            remoteCard
                        }
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                    } else {
                        VStack(spacing: 20) {
                            timerCard
                            remoteCard

                        }
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                    }

                }

                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

private struct TopBarView: View {
    var body: some View {
        HStack {
            Button {
                    // action
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("연결 끊기")
                }
                .font(.callout)
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .foregroundStyle(Color.borderLine)
                )
            }

            Spacer()

            Button {
                    // action
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
        .padding(.horizontal, 30)
    }
}

private struct TitleView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("촬영 방식 선택")
                .font(.largeTitle)
                .foregroundColor(.white)

            Text("어떻게 촬영하시겠어요?")
                .font(.callout)
                .foregroundColor(.gray)
        }
    }
}

private struct SelectionCard: View {
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

                VStack(spacing: 10) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    if !descriptionTruncated {
                        DescriptionLabel(description: description)
                            .modifier(
                                TruncationDetectionModifier(
                                    text: description,
                                    font: .subheadline,
                                    lineLimit: 2,
                                    isTruncated: $descriptionTruncated
                                )
                            )
                    }
                }
            }
            .frame(maxWidth: 400, maxHeight: 350)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.cardView)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.borderLine, lineWidth: 3)
            )
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
    let font: Font
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
