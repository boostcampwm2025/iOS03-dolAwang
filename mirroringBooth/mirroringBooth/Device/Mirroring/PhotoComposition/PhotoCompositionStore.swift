//
//  PhotoCompositionStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import SwiftUI

@Observable
final class PhotoCompositionStore: StoreProtocol {
    struct State {
        var photos: [Photo] = []
        var selectedPhotos: [Photo] = []
        var currentSelectionCount: Int = 0
        var selectedLayout: LayoutAsset = .oneByOne
        var selectedFrame: FrameAsset = .black
        var isCompletedButtonDisabled: Bool {
            return currentSelectionCount < selectedLayout.capacity
        }
    }

    enum Intent {
        case onAppear
        case selectPhoto(Int) // 사진을 선택한 경우 인덱스
        case selectLayout(LayoutAsset)
        case selectFrame(FrameAsset)
    }

    enum Result {
        case setPhotos([Photo])
        case selectPhoto(Int)
        case deselectPhoto(Int)
        case setSelectionCount(Int)
        case setLayout(LayoutAsset)
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
            let newCapacity = layout.capacity
            let oldCapacity = state.selectedLayout.capacity

            // capacity가 줄어들고, 현재 선택된 이미지의 개수가 capacity를 초과하는 경우만 처리합니다.
            if newCapacity < oldCapacity && copyState.currentSelectionCount > newCapacity {
                // 초과된 사진 사진들의 selectNumber 제거
                for index in 0 ..< copyState.photos.count {
                    if let selectNumber = copyState.photos[index].selectNumber,
                       selectNumber > newCapacity {
                        copyState.photos[index] = Photo(
                            id: copyState.photos[index].id,
                            url: copyState.photos[index].url,
                            selectNumber: nil
                        )
                    }
                }

                copyState.selectedPhotos = copyState.photos
                    .filter { $0.selectNumber != nil }
                    .sorted { ($0.selectNumber ?? 0) < ($1.selectNumber ?? 0) }

                copyState.currentSelectionCount = copyState.selectedPhotos.count
            }
            copyState.selectedLayout = layout
            state = copyState

        case .setFrame(let frame):
            state.selectedFrame = frame
        case let .setSelectionCount(count):
            state.currentSelectionCount = count
        }

        self.state = state
    }
}
