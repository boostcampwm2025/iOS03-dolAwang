//
//  FrameSelectionView.swift
//  mirroringBooth
//
//  Created by Liam on 1/9/26.
//

import SwiftUI

struct FrameSelectionView: View {
    let store: CaptureResultStore
    @State private var rows: Int = 0
    @State private var columns: Int = 0
    @State private var frameColor: Color = .black

    var body: some View {
        VStack {
            HStack {
                Button {
                    rows = 1
                    columns = 1
                } label: {
                    VStack {
                        Image(systemName: "square.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                        Text("1x1")
                    }
                }

                Button {
                    rows = 1
                    columns = 2
                } label: {
                    VStack {
                        Image(systemName: "rectangle.split.2x1.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                        Text("1x2")
                    }
                }

                Button {
                    rows = 1
                    columns = 3
                } label: {
                    VStack {
                        Image(systemName: "rectangle.grid.1x3.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                        Text("1x3")
                    }
                }

                Button {
                    rows = 2
                    columns = 2
                } label: {
                    VStack {
                        Image(systemName: "rectangle.split.2x2.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                        Text("2x2")
                    }
                }

                Button {
                    rows = 2
                    columns = 3
                } label: {
                    VStack {
                        Image(systemName: "square.grid.3x2.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                        Text("2x3")
                    }
                }
            }

            Divider()
                .background(Color.primary)

            VStack {
                FrameColorButtonView(action: {
                    frameColor = .black
                }, color: .black, description: "Basic Black")
                FrameColorButtonView(action: {
                    frameColor = .white
                }, color: .white, description: "Basic White")
            }
            .padding()

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
                    .padding()
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

private struct FrameColorButtonView: View {
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

