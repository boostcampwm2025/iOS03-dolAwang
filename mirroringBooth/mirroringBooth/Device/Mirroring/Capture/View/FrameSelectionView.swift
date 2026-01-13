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
    @State private var rows: Int = 0
    @State private var columns: Int = 0
    @State private var frameColor: Color = .black

    var body: some View {
        VStack {
            LayoutButtonView(
                rows: $rows,
                columns: $columns,
                frameColor: $frameColor
            )

            Divider()
                .background(Color.main)

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
                    .padding()
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
                    Text("촬영 완료하기")
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.buttonComponent)
                                .strokeBorder(Color.borderLine, lineWidth: 2)
                                .frame(minHeight: 44)
                        }
                }
            }
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

    var body: some View {
        HStack {
            LayoutButton(
                rows: $rows,
                columns: $columns,
                image: "square.fill",
                row: 1,
                column: 1
            )

            LayoutButton(
                rows: $rows,
                columns: $columns,
                image: "rectangle.split.2x1.fill",
                row: 2,
                column: 1
            )

            LayoutButton(
                rows: $rows,
                columns: $columns,
                image: "rectangle.grid.1x3.fill",
                row: 1,
                column: 3
            )

            LayoutButton(
                rows: $rows,
                columns: $columns,
                image: "rectangle.split.2x2.fill",
                row: 2,
                column: 2
            )

            LayoutButton(
                rows: $rows,
                columns: $columns,
                image: "square.grid.3x2.fill",
                row: 3,
                column: 2
            )
        }
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
    var text: String { "\(row)x\(column)" }

    var body: some View {
        Button {
            rows = row
            columns = column
        } label: {
            VStack {
                if horizontalSizeClass != .compact {
                    Image(systemName: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .padding()
                    Text(text)
                } else {
                    SimpleLayoutButtonView(text: text)
                }
            }
            .foregroundStyle(Color.secondary)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.primary, lineWidth: 1)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

private struct SimpleLayoutButtonView: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(Color.primary)
            .lineLimit(1)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.buttonComponent)
            }
    }
}
