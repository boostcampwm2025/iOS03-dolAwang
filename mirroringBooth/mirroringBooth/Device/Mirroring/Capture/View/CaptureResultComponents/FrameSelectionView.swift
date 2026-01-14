//
//  FrameSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/9/26.
//

import SwiftUI

/// 레이아웃/프레임 선택 + 완료 버튼
struct FrameSelectionView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    let store: CaptureResultStore

    private var isRegularSize: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading) {
            layoutSection
            frameSection
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.trailing, 10)
    }
}

// MARK: - Components

private extension FrameSelectionView {
    var layoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                isRegularSize ? "레이아웃" : "레이아웃 & 프레임",
                systemImage: "rectangle.grid.2x2"
            )
            .font(isRegularSize ? .callout.bold() : .caption.bold())
            .foregroundStyle(.primary)

            layoutButtonList
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var frameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isRegularSize {
                Label("프레임 디자인", systemImage: "paintpalette")
                    .font(.callout.bold())
                    .foregroundStyle(.primary)

                ScrollView {
                    VStack {
                        ForEach(FrameAsset.allCases) { frame in
                            frameColorButton(with: frame, description: frame.rawValue) {
                                store.send(.selectFrame(frame))
                            }
                        }
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                    ForEach(FrameAsset.allCases) { frame in
                        Button {
                            store.send(.selectFrame(frame))
                        } label: {
                            frameIcon(with: frame)
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    @ViewBuilder
    var layoutButtonList: some View {
        var isCompact: Bool {
            UIDevice.current.userInterfaceIdiom == .phone
            && UIScreen.main.bounds.width < UIScreen.main.bounds.height
        }
        let gridItems = Array(repeating: GridItem(.flexible()), count: 3)

        if isCompact {
            LazyVGrid(columns: gridItems) {
                ForEach(PhotoFrameLayout.allCases) { layout in
                    layoutButton(layout.icon) {
                        store.send(.selectLayout(layout))
                    }
                }
            }
        } else {
            HStack {
                ForEach(PhotoFrameLayout.allCases) { layout in
                    layoutButton(layout.icon) {
                        store.send(.selectLayout(layout))
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    func frameColorButton(
        with frame: FrameAsset,
        description: String,
        _ action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                frameIcon(with: frame)
                    .padding()

                Text(description)
                    .font(.callout.bold())
                    .foregroundStyle(Color.primary)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.label).opacity(0.02))
                    .strokeBorder(Color.borderLine, lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    func frameIcon(with frame: FrameAsset) -> some View {
        if let icon = frame.image {
            Image(uiImage: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    func layoutButton(_ iconString: String, _ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(iconString)
                .resizable()
                .renderingMode(.template)
                .font(.footnote)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: 60, maxHeight: 60)
                .padding(2)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.primary, lineWidth: 2)
                        .foregroundStyle(Color.secondary)
                }
                .aspectRatio(contentMode: .fit)
        }
    }
}
