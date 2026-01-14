//
//  PhotoGrid.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-13.
//

import SwiftUI

/// 촬영된 사진 목록 그리드
struct PhotoGrid: View {
    var store: CaptureResultStore
    let geometry: GeometryProxy

    private var rows: Int {
        calculateRows(width: geometry.size.width, height: geometry.size.height)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(
                rows: Array(repeating: GridItem(.flexible(), spacing: 12), count: rows),
                spacing: 20
            ) {
                ForEach(Array(zip(store.state.photos.indices, store.state.photos)), id: \.1.id) { index, photo in
                    PhotoItem(photo: photo, index: index, rows: rows, geometry: geometry) {
                        withAnimation(.spring(response: 0.3)) {
                            store.send(.selectPhoto(index))
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }

    private func calculateRows(width: CGFloat, height: CGFloat) -> Int {
        if UIScreen.main.bounds.width < UIScreen.main.bounds.height { return 2 }
        let minItemHeight: CGFloat = 110
        let spacing: CGFloat = 20
        let targetRows = min(Int((height + spacing) / (minItemHeight + spacing)), 4)
        return max(targetRows, 2)
    }
}

private struct PhotoItem: View {
    let photo: Photo
    let index: Int
    let rows: Int
    let geometry: GeometryProxy
    let onTap: () -> Void

    var body: some View {
        Group {
            switch photo.state {
            case .receiving(let progress):
                ReceivingView(progress: progress)

            case .completed(let data):
                if let uiImage = UIImage(data: data) {
                    PhotoCell(uiImage: uiImage, index: index, selectedNumber: photo.selectNumber)
                        .onTapGesture { onTap() }
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.yellow)
                }

            case .failed:
                FailedView()
            }
        }
        .background(Color.gray)
        .cornerRadius(8)
        .clipped()
        .frame(maxHeight: 200)
        .frame(height: geometry.size.height / CGFloat(rows) - 20)
    }
}

private struct ReceivingView: View {
    let progress: Double

    var body: some View {
        VStack {
            ProgressView(value: progress)
            Text("사진 수신 중... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FailedView: View {
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text("수신 실패")
        }
        .foregroundStyle(.red)
    }
}

private struct PhotoCell: View {
    let uiImage: UIImage
    let index: Int
    let selectedNumber: Int?

    private var isSelected: Bool {
        selectedNumber != nil
    }

    var body: some View {
        ZStack {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipped()

            if isSelected {
                Color.selectionBlue.opacity(0.25)
            }

            SelectionBorder(selectedNumber: selectedNumber)
        }
        .aspectRatio(4/3, contentMode: .fit)
        .cornerRadius(12)
        .clipped()
    }
}

private struct SelectionBorder: View {
    let selectedNumber: Int?

    var body: some View {
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
}
