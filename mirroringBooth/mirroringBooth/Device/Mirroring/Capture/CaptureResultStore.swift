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
        var currentSelectionCount: Int = 0
        var selectedLayout: PhotoFrameLayout = .oneByOne
        var selectedFrame: FrameAsset = .black
    }

    enum Intent {
        case onAppear
        case selectPhoto(Int) // 사진을 선택한 경우 인덱스
        case selectLayout(PhotoFrameLayout)
        case selectFrame(FrameAsset)
    }

    enum Result {
        case setPhotos([Photo])
        case selectPhoto(Int)
        case deselectPhoto(Int)
        case setSelectionCount(Int)
        case setLayout(PhotoFrameLayout)
        case setFrame(FrameAsset)
    }

    var state: State = .init()

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            let cacheManger = PhotoCacheManager.shared
            let photos: [Photo] = (0..<10).map { index in
                let url = cacheManger.getPhotoURL(index: index)
                return Photo(id: UUID(), url: url, selectNumber: nil)
            }
            return [.setPhotos(photos)]
        case let .selectPhoto(index):
            if state.photos[index].selectNumber == nil {
                guard state.currentSelectionCount < state.selectedLayout.capacity else {
                    return []
                }
                return [
                    .selectPhoto(index),
                    .setSelectionCount(state.currentSelectionCount + 1)
                ]
            } else {
                return [
                    .deselectPhoto(index),
                    .setSelectionCount(state.currentSelectionCount - 1)
                ]
            }
        case .selectLayout(let layout):
            return [.setLayout(layout)]

        case .selectFrame(let frame):
            return [.setFrame(frame)]
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case let .setPhotos(photos):
            state.photos = photos

        case let .selectPhoto(index):
            let photo = state.photos[index]
            state.photos[index] = Photo(id: photo.id, url: photo.url, selectNumber: state.currentSelectionCount + 1)
            state.selectedPhotos.append(state.photos[index])

        case let .deselectPhoto(index):
            var copyState = self.state
            guard let number = copyState.photos[index].selectNumber else { return }
            copyState.photos[index] = Photo(
                id: copyState.photos[index].id,
                url: copyState.photos[index].url,
                selectNumber: nil
            )
            copyState.selectedPhotos.remove(at: number - 1)
            for (index, photo) in copyState.photos.enumerated() {
                if let iterator = photo.selectNumber, iterator > number {
                    copyState.photos[index] = Photo(
                        id: photo.id,
                        url: photo.url,
                        selectNumber: iterator - 1
                    )
                }
            }
            state = copyState

        case .setLayout(let layout):
            var copyState = state
            for index in 0 ..< copyState.photos.count {
                copyState.photos[index] = Photo(
                    id: copyState.photos[index].id,
                    url: copyState.photos[index].url,
                    selectNumber: nil
                )
            }
            copyState.selectedPhotos = []
            copyState.currentSelectionCount = 0
            copyState.selectedLayout = layout
            copyState.selectedFrame = state.selectedFrame
            state = copyState

        case .setFrame(let frame):
            state.selectedFrame = frame
        case let .setSelectionCount(count):
            state.currentSelectionCount = count
        }

        self.state = state
    }
}
