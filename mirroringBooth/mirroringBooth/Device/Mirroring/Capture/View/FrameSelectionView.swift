//
//  FrameSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/9/26.
//

import SwiftUI

struct FrameSelectionView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    let store: CaptureResultStore
    @State private var rows: Int = 1
    @State private var columns: Int = 1
    @State private var frameColor: Color = .black

    var body: some View {
        VStack(alignment: .leading) {
            if horizontalSizeClass == .regular
                && verticalSizeClass == .regular {
                Label("레이아웃", systemImage: "rectangle.grid.2x2")
                    .bold()
                    .foregroundStyle(.primary)
            } else {
                Label("레이아웃 & 프레임", systemImage: "rectangle.grid.2x2")
                    .bold()
                    .foregroundStyle(.primary)
            }

            LayoutButtonView(
                rows: $rows,
                columns: $columns,
                frameColor: $frameColor
            )

            if horizontalSizeClass == .regular
                && verticalSizeClass == .regular {
                HStack {
                    Label("프레임 디자인", systemImage: "paintpalette")
                        .bold()
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }

            VStack {
                if horizontalSizeClass == .compact
                    || verticalSizeClass == .compact {
                    HStack {
                        SimpleColorButton(
                            action: {
                                frameColor = .black
                            },
                            color: .black
                        )
                        SimpleColorButton(
                            action: {
                                frameColor = .white
                            },
                            color: .white
                        )
                    }
                    .padding(16)
                } else {
                    VStack {
                        FrameColorButton(action: {
                            frameColor = .black
                        }, color: .black, description: "Basic Black")
                        FrameColorButton(action: {
                            frameColor = .white
                        }, color: .white, description: "Basic White")
                    }
                    .padding()
                }

                Spacer()

                Button {

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
            .padding(.top, -16)
        }
        .onChange(of: rows) {
            store.send(.selectLayout(rows, columns, frameColor))
        }
        .onChange(of: columns) {
            store.send(.selectLayout(rows, columns, frameColor))
        }
        .onChange(of: frameColor) {
            store.send(.selectLayout(rows, columns, frameColor))
        }
    }
}

private struct LayoutButtonView: View {
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
            image: "square.fill",
            row: 1,
            column: 1
        )
    }

    private var button1x2: some View {
        LayoutButton(
            rows: $rows,
            columns: $columns,
            image: "rectangle.split.2x1.fill",
            row: 1,
            column: 2
        )
    }

    private var button3x1: some View {
        LayoutButton(
            rows: $rows,
            columns: $columns,
            image: "rectangle.grid.1x3.fill",
            row: 3,
            column: 1
        )
    }

    private var button2x2: some View {
        LayoutButton(
            rows: $rows,
            columns: $columns,
            image: "rectangle.split.2x2.fill",
            row: 2,
            column: 2
        )
    }

    private var button2x3: some View {
        LayoutButton(
            rows: $rows,
            columns: $columns,
            image: "square.grid.3x2.fill",
            row: 2,
            column: 3
        )
    }
}

private struct FrameColorButton: View {
    let action: () -> Void
    let color: Color
    let description: String

    var body: some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(color)
                    .aspectRatio(1, contentMode: .fit)
                    .padding()

                Text(description)
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.buttonComponent)
                    .strokeBorder(Color.borderLine, lineWidth: 2)
            }
        }
    }
}

private struct SimpleColorButton: View {
    let action: () -> Void
    let color: Color

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 30, height: 30)
                .foregroundStyle(color)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                }
                .aspectRatio(1, contentMode: .fit)
        }
    }
}

private struct LayoutButton: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var rows: Int
    @Binding var columns: Int
    let image: String
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
                .aspectRatio(1, contentMode: .fit)
                .foregroundStyle(Color.primary)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.primary, lineWidth: 1)
                        .foregroundStyle(Color.secondary)
                }
        }
    }
}
