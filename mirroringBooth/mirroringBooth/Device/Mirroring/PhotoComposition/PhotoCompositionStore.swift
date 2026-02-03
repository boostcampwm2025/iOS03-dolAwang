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

    private(set) var state: State = .init()

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            let cacheManger = PhotoCacheManager.shared
            let photos: [Photo] = (0..<10).map { index in
                let url = cacheManger.getPhotoURL(index: index)
                return Photo(id: UUID(), url: url, selectNumber: nil)
            }
            return [.setPhotos(photos)]

        case .selectPhoto(let index):
            if state.photos[index].selectNumber == nil {
                guard state.currentSelectionCount < state.selectedLayout.capacity else {
                    return []
                }
                return [.selectPhoto(index),
                    .setSelectionCount(state.currentSelectionCount + 1)]
            } else {
                return [.deselectPhoto(index),
                    .setSelectionCount(state.currentSelectionCount - 1)]
            }

        case .selectLayout(let layout):
            let newCapacity = layout.capacity
            let oldCapacity = state.selectedLayout.capacity
            var results: [Result] = []
            
            // capacity가 줄어들고, 현재 선택된 이미지의 개수가 capacity를 초과하는 경우
            if newCapacity < oldCapacity && state.currentSelectionCount > newCapacity {
                for (index, photo) in state.photos.enumerated() {
                    if let selectNumber = photo.selectNumber, selectNumber > newCapacity {
                        results.append(.deselectPhoto(index))
                    }
                }
                results.append(.setSelectionCount(newCapacity))
            }
            results.append(.setLayout(layout))
            return results

        case .selectFrame(let frame):
            return [.setFrame(frame)]
        }
    }

    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setPhotos(let photos):
            state.photos = photos

        case .selectPhoto(let index):
            state.photos[index].selectNumber = state.currentSelectionCount + 1
            state.selectedPhotos.append(state.photos[index])

        case .deselectPhoto(let index):
            guard let number = state.photos[index].selectNumber else { return }
            state.photos[index].selectNumber = nil
            state.selectedPhotos.remove(at: number - 1)
            for index in state.photos.indices where state.photos[index].selectNumber ?? 0 > number {
                state.photos[index].selectNumber? -= 1
            }

        case .setLayout(let layout):
            state.selectedLayout = layout

        case .setFrame(let frame):
            state.selectedFrame = frame

        case .setSelectionCount(let count):
            state.currentSelectionCount = count
        }

        self.state = state
    }
}
