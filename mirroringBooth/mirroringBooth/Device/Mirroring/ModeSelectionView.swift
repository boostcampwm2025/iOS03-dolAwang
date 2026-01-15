//
//  ModeSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/6/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @Environment(Router.self) var router: Router
    private let advertiser: Advertiser

    init(advertiser: Advertiser) {
        self.advertiser = advertiser
    }

    var timerCard: some View {
        SelectionCard(
            iconName: "stopwatch",
            iconColor: Color.main,
            title: "타이머 모드",
            description: "80초 동안 8초 간격으로\n자동 촬영합니다."
        ) {
            // 촬영 기기에게 타이머 모드 선택 알림
            advertiser.sendCommand(.selectedTimerMode)
            router.push(to: MirroringRoute.streaming(advertiser, isTimerMode: true))
        }
    }

    var remoteCard: some View {
        SelectionCard(
            iconName: "target", // SF Symbol
            iconColor: Color.remote,
            title: "리모콘 모드",
            description: "나의 Apple Watch에서 \n직접 셔터를 누르세요."
        ) {
            router.push(to: MirroringRoute.streaming(advertiser, isTimerMode: false))
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
            .padding(.horizontal)
        }
    }
}

private struct TopBarView: View {
    var body: some View {
        HStack {
            DisconnectButtonView(action: {})

            Spacer()

            LightButtonView(action: {})
        }
        .padding(.horizontal, 30)
    }
}

private struct TitleView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("촬영 방식 선택")
                .font(.title.bold())
                .foregroundColor(.primary)

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
