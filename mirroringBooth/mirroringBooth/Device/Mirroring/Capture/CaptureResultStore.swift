//
//  CaptureResultStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import Foundation

@Observable
final class CaptureResultStore: StoreProtocol {
    struct State {
        var photos: [Photo] = []
        var maxSelection: Int
        var currentSelectionCount: Int = 0
    }

    enum Intent {
        case onAppear
        // 사진을 선택한 경우 인덱스
        case selectPhoto(Int)
    }

    enum Result {
        case setPhotos([Photo])
        case selectPhoto(Int)
        case deselectPhoto(Int)
        case increaseSelectionCount
        case decreaseSelectionCount
    }

    var state: State = .init(maxSelection: 4)
    let advertiser: Advertisier

    init(advertiser: Advertisier) {
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
        }
    }

    func reduce(_ result: Result) {
        switch result {
        case let .setPhotos(photos):
            state.photos = photos
        case let .selectPhoto(index):
            state.photos[index].selectNumber = state.currentSelectionCount + 1
        case let .deselectPhoto(index):
            guard let number = self.state.photos[index].selectNumber else { return }
            state.photos[index].selectNumber = nil
            for (index, photo) in self.state.photos.enumerated() {
                if let iterator = photo.selectNumber, iterator > number {
                    state.photos[index].selectNumber = iterator - 1
                }
            }
        case .increaseSelectionCount:
            state.currentSelectionCount += 1
        case .decreaseSelectionCount:
            state.currentSelectionCount -= 1
        }
    }
}
