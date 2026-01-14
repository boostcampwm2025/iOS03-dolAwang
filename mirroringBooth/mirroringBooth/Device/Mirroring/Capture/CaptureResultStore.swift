//
//  CaptureResultStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

@Observable
final class CaptureResultStore: StoreProtocol {
    struct State {
        var photos: [Photo] = []
        var selectedPhotos: [Photo] = []
        var maxSelection: Int = 1
        var currentSelectionCount: Int = 0
        var layoutRowCount: Int = 1
        var layoutColumnCount: Int = 1
        var layoutColor: Color = .black
    }

    enum Intent {
        case onAppear
        case selectPhoto(Int) // 사진을 선택한 경우 인덱스
        case selectLayout(Int, Int, Color) // 레이아웃 row x column
    }

    enum Result {
        case setPhotos([Photo])
        case selectPhoto(Int)
        case deselectPhoto(Int)
        case increaseSelectionCount
        case decreaseSelectionCount
        case setLayout(Int, Int, Color)
        case setColor(Color)
    }

    var state: State = .init()

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            let cacheManger = PhotoCacheManager.shared
            let photos: [Photo] = (0..<10).map { index in
                let url = cacheManger.getPhotoURL(index: index)
                return Photo(id: UUID(), url: url)
            }
            return [.setPhotos(photos)]
        case let .selectPhoto(index):
            if state.photos[index].selectNumber == nil {
                guard state.currentSelectionCount < state.maxSelection else { return [] }
                return [.selectPhoto(index), .increaseSelectionCount]
            } else {
                return [.deselectPhoto(index), .decreaseSelectionCount]
            }
        case let .selectLayout(row, column, color):
            if state.layoutRowCount == row && state.layoutColumnCount == column {
                if state.layoutColor == color {
                    return []
                } else {
                    return [.setColor(color)]
                }
            }
            return [
                .setLayout(row, column, color)
            ]
        }
    }

    func reduce(_ result: Result) {
        switch result {
        case let .setPhotos(photos):
            state.photos = photos
        case let .selectPhoto(index):
            state.photos[index].selectNumber = state.currentSelectionCount + 1
            state.selectedPhotos.append(state.photos[index])
        case let .deselectPhoto(index):
            var copyState = self.state
            guard let number = copyState.photos[index].selectNumber else { return }
            copyState.photos[index].selectNumber = nil
            copyState.selectedPhotos.remove(at: number - 1)
            for (index, photo) in copyState.photos.enumerated() {
                if let iterator = photo.selectNumber, iterator > number {
                    copyState.photos[index].selectNumber = iterator - 1
                }
            }
            state = copyState
        case .increaseSelectionCount:
            state.currentSelectionCount += 1
        case .decreaseSelectionCount:
            state.currentSelectionCount -= 1
        case let .setLayout(row, column, color):
            var copyState = state
            for index in 0 ..< copyState.photos.count {
                copyState.photos[index].selectNumber = nil
            }
            copyState.selectedPhotos = []
            copyState.maxSelection = row * column
            copyState.currentSelectionCount = 0
            copyState.layoutRowCount = row
            copyState.layoutColumnCount = column
            copyState.layoutColor = color
            state = copyState
        case let .setColor(color):
            state.layoutColor = color
        }
    }
}
