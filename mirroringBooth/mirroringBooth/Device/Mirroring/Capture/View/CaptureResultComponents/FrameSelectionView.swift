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
    @State private var rows: Int = 1
    @State private var columns: Int = 1
    @State private var frameColor: Color = .black

    private var isRegularSize: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading) {
            layoutSection
            frameSection
            Spacer()
            completeButton
        }
        .padding(.top, 5)
        .padding(.bottom)
        .padding(.trailing, 10)
        .onChange(of: rows) { store.send(.selectLayout(rows, columns, frameColor)) }
        .onChange(of: columns) { store.send(.selectLayout(rows, columns, frameColor)) }
        .onChange(of: frameColor) { store.send(.selectLayout(rows, columns, frameColor)) }
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

            LayoutButtonView(rows: $rows, columns: $columns, frameColor: $frameColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var frameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isRegularSize {
                Label("프레임 디자인", systemImage: "paintpalette")
                    .font(.callout.bold())
                    .foregroundStyle(.primary)
            }

            if isRegularSize {
                VStack {
                    frameColorButton(with: .black, description: "Basic Black") {
                        frameColor = .black
                    }
                    frameColorButton(with: .white, description: "Basic White") {
                        frameColor = .white
                    }
                }
            } else {
                HStack {
                    simpleColorButton(with: .black) {
                        frameColor = .black
                    }
                    simpleColorButton(with: .white) {
                        frameColor = .white
                    }
                }
            }
        }
    }

    var completeButton: some View {
        Button {
            // TODO: 완료 버튼 액션
        } label: {
            Text("편집 완료하기")
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.main.opacity(0.3))
                        .strokeBorder(Color.borderLine, lineWidth: 2)
                        .frame(minHeight: 44)
                }
        }
    }

    struct LayoutButtonView: View {
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        @Binding var rows: Int
        @Binding var columns: Int
        @Binding var frameColor: Color

        private var isCompact: Bool {
            UIDevice.current.userInterfaceIdiom == .phone
            && UIScreen.main.bounds.width < UIScreen.main.bounds.height
        }
        private let gridItems = Array(repeating: GridItem(.flexible()), count: 3)

        var body: some View {
            if isCompact {
                VStack {
                    LazyVGrid(columns: gridItems) {
                        button1x1; button1x2; button3x1
                        button2x2; button2x3
                    }
                }
            } else {
                HStack {
                    button1x1; button1x2; button3x1; button2x2; button2x3
                }
                .padding(.horizontal)
            }
        }

        private var button1x1: some View {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                row: 1,
                column: 1
            )
        }

        private var button1x2: some View {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                row: 2,
                column: 1
            )
        }

        private var button3x1: some View {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                row: 4,
                column: 1
            )
        }

        private var button2x2: some View {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                row: 2,
                column: 2
            )
        }

        private var button2x3: some View {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                row: 2,
                column: 3
            )
        }
    }

    func frameColorButton(
        with color: Color,
        description: String,
        _ action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                colorBox(with: color)
                    .padding()

                Text(description)
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

    func simpleColorButton(with color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            colorBox(with: color)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                }
        }
    }

    func colorBox(with color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .frame(width: 30, height: 30)
            .foregroundStyle(color)
            .aspectRatio(1, contentMode: .fit)
    }

    struct LayoutButton: View {
        @Binding var rows: Int
        @Binding var columns: Int
        let row: Int
        let column: Int
        var imageName: String {
            "layout\(row)x\(column)"
        }

        var body: some View {
            Button {
                rows = row
                columns = column
            } label: {
                Image(imageName)
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
}
