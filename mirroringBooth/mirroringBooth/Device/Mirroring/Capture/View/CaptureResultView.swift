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
                            .frame(height: geometry.size.height / 2)
                            .padding()
                        } else {
                            EmptyView()
                                .frame(height: geometry.size.height / 2)
                        }

                        Divider()
                            .background(.primary)

                        FrameSelectionView(store: store)
                            .frame(height: geometry.size.height / 2)
                    }
                    // 화면 표시 비율
                    .frame(width: geometry.size.width * 0.33)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
            store.send(.selectLayout(4, 1, .blue))
        }
    }
}

private struct PhotoGridView: View {
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
                ScrollView(.horizontal) {
                    LazyHGrid(
                        rows: Array(
                            repeating: GridItem(.flexible(), spacing: 12),
                            // 4열, 안 되면 2열 배치
                            count: geometry.size.height > 800 ? 4 : 2
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
                            .frame(height: geometry.size.height / 2 - 20)
                        }
                    }
                }
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
        }
        .padding()
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
