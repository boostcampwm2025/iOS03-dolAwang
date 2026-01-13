//
//  CaptureResultView.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

struct CaptureResultView: View {
    @State var store: CaptureResultStore

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                if geometry.size.height > geometry.size.width {
                    VStack {
                        PhotoGridView(store: store)

                        Divider()
                            .background(.primary)

                        GeometryReader { _ in
                            HStack {
                                if store.state.layoutRowCount != 0
                                    && store.state.layoutColumnCount != 0 {
                                    FrameView(
                                        photos: store.state.selectedPhotos,
                                        rows: store.state.layoutRowCount,
                                        columns: store.state.layoutColumnCount,
                                        frameColor: store.state.layoutColor
                                    )
                                    .frame(width: geometry.size.width / 2)
                                    .padding(.horizontal, 12)
                                } else {
                                    EmptyView()
                                        .frame(height: geometry.size.height / 2)
                                }

                                Divider()
                                    .background(.primary)

                                FrameSelectionView(store: store)
                                    .padding(.bottom, 16)
                            }
                            // 화면 표시 비율
                            .frame(height: geometry.size.height * 0.5)
                        }
                    }

                } else {
                    HStack {
                        PhotoGridView(store: store)

                        Divider()
                            .background(.primary)

                        VStack {
                            if store.state.layoutRowCount != 0
                                && store.state.layoutColumnCount != 0 {
                                FrameView(
                                    photos: store.state.selectedPhotos,
                                    rows: store.state.layoutRowCount,
                                    columns: store.state.layoutColumnCount,
                                    frameColor: store.state.layoutColor
                                )
                                .frame(height: geometry.size.height / 2 - 12)
                                .padding(.vertical, 12)
                            } else {
                                EmptyView()
                                    .frame(height: geometry.size.height / 2)
                            }

                            Divider()
                                .background(.primary)

                            FrameSelectionView(store: store)
                                .padding(.bottom, 16)
                        }
                        // 화면 표시 비율
                        .frame(width: geometry.size.width * 0.33)
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

private struct PhotoGridView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var store: CaptureResultStore

    var body: some View {
        VStack(alignment: .leading) {
            // 제목 및 Description
            Text("사진 선택 (\(store.state.currentSelectionCount)/\(store.state.maxSelection))")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("촬영된 10장의 사진 중 마음에 드는 사진을 골라주세요.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 16)

            // 사진 표시 구역
            GeometryReader { geometry in
                let rows = calculateRows(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                ScrollView(.horizontal) {
                    LazyHGrid(
                        rows: Array(
                            repeating: GridItem(.flexible(), spacing: 12),
                            // 4열, 작은 기기에서 2열 배치
                            count: rows
                        ),
                        spacing: 20
                    ) {
                        let photos = store.state.photos
                        ForEach(Array(zip(photos.indices, photos)), id: \.1.id) { index, photo in
                            Group {
                                switch photo.state {
                                case .receiving(let progress):
                                    VStack {
                                        ProgressView(value: progress)
                                        Text("사진 수신 중... \(Int(progress * 100))%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                case .completed(let data):
                                    if let uiImage = UIImage(data: data) {
                                        PhotoCell(
                                            uiImage: uiImage,
                                            index: index,
                                            selectedNumber: photo.selectNumber
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3)) {
                                                self.store.send(.selectPhoto(index))
                                            }
                                        }
                                    } else {
                                        Image(systemName: "questionmark.circle")
                                            .foregroundStyle(.yellow)
                                    }

                                case .failed:
                                    VStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("수신 실패")
                                    }
                                    .foregroundStyle(.red)
                                }
                            }
                            .background(Color.gray)
                            .cornerRadius(8)
                            .clipped()
                            .frame(maxHeight: 200)
                            // 공간에 맞는 높이 조정, 아래 줄 패딩만큼 여유
                            .frame(height: geometry.size.height / CGFloat(rows) - 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .padding()
    }

    private func calculateRows(width: CGFloat, height: CGFloat) -> Int {
        // 세로모드일 경우 2줄 배치
        if UIDevice.current.orientation.isPortrait { return 2 }
        // 이외의 경우 최소 Height를 유지하는 선에서 최대 4줄 배치
        let minItemHeight: CGFloat = 110
        let spacing: CGFloat = 20
        let targetRows = min(Int((height + spacing) / (minItemHeight + spacing)), 4)
        return max(targetRows, 2)
    }
}

private struct PhotoCell: View {
    let uiImage: UIImage
    let index: Int
    let selectedNumber: Int?

    var body: some View {
        ZStack {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipped()

            if selectedNumber != nil {
                Color.selectionBlue.opacity(0.25)
            }

            if let selectedNumber {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.selectionBlue, lineWidth: 4)

                Text("\(selectedNumber)")
                    .font(.system(size: 40).bold())
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary, lineWidth: 1)
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
        .cornerRadius(12)
        .clipped()
    }
}
