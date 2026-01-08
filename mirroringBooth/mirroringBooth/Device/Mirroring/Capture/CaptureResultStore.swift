//
//  CaptureResultStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/7/26.
//

import Foundation
import SwiftUI

@Observable
final class CaptureResultStore: StoreProtocol {
    struct State {
        var photos: [Photo] = []
        var selectedPhotos: [Photo] = []
        var maxSelection: Int
        var currentSelectionCount: Int = 0
        var layoutRowCount: Int = 0
        var layoutColumnCount: Int = 0
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
        case let .selectLayout(row, column, color):
            if state.layoutRowCount == row && state.layoutColumnCount == column {
                return []
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
            guard let number = self.state.photos[index].selectNumber else { return }
            state.photos[index].selectNumber = nil
            state.selectedPhotos.remove(at: number - 1)
            for (index, photo) in self.state.photos.enumerated() {
                if let iterator = photo.selectNumber, iterator > number {
                    state.photos[index].selectNumber = iterator - 1
                }
            }
        case .increaseSelectionCount:
            state.currentSelectionCount += 1
        case .decreaseSelectionCount:
            state.currentSelectionCount -= 1
        case let .setLayout(row, column, color):
            for index in 0 ..< state.photos.count {
                state.photos[index].selectNumber = nil
            }
            state.currentSelectionCount = 0
            state.layoutRowCount = row
            state.layoutColumnCount = column
            state.layoutColor = color
        }
    }
}
