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
        case increaseSelectionCount
        case decreaseSelectionCount
        case setLayout(PhotoFrameLayout)
        case setFrame(FrameAsset)
    }

    var state: State = .init()
    let advertiser: Advertiser

    init(advertiser: Advertiser) {
        self.advertiser = advertiser
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .onAppear:
            return [.setPhotos(advertiser.receivedPhotos)]

        case let .selectPhoto(index):
            if state.photos[index].selectNumber == nil {
                guard state.currentSelectionCount < state.maxSelection else { return [] }
                return [.selectPhoto(index), .increaseSelectionCount]
            } else {
                return [.deselectPhoto(index), .decreaseSelectionCount]
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

        case .setLayout(let layout):
            state.selectedLayout = layout

        case .setFrame(let frame):
            state.selectedFrame = frame
        }

        self.state = state
    }
}
