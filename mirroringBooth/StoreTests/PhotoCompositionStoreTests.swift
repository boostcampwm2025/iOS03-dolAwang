//
//  PhotoCompositionStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Foundation
import Testing
@testable import mirroringBooth

@MainActor
struct PhotoCompositionStoreTests {

    // MARK: - Helper

    private func makeSUT() -> PhotoCompositionStore {
        let store = PhotoCompositionStore()
        let photos = makePhotos(count: 10)
        store.reduce(.setPhotos(photos))
        return store
    }

    private func makePhotos(count: Int) -> [Photo] {
        (0..<count).map { index in
            Photo(
                id: .init(),
                url: URL(fileURLWithPath: ""),
                selectNumber: nil
            )
        }
    }

    // MARK: - onAppear

    @Test func 화면에_진입하면_10개의_미선택_사진이_로드됨() {
        let store = PhotoCompositionStore()

        store.send(.onAppear)

        #expect(store.state.photos.count == 10)
        #expect(store.state.photos.allSatisfy { $0.selectNumber == nil })
    }

    // MARK: - 사진 선택

    @Test func 사진을_선택하면_선택번호와_카운트가_반영됨() {
        let store = makeSUT()

        store.send(.selectPhoto(0))

        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.selectedPhotos.count == 1)
        #expect(store.state.currentSelectionCount == 1)
    }

    @Test func 여러_사진을_순서대로_선택하면_선택번호가_순차적으로_부여됨() {
        let store = makeSUT()
        store.reduce(.setLayout(.twoByTwo)) // capacity 4

        store.send(.selectPhoto(0))
        store.send(.selectPhoto(1))
        store.send(.selectPhoto(2))

        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.photos[1].selectNumber == 2)
        #expect(store.state.photos[2].selectNumber == 3)
        #expect(store.state.selectedPhotos.count == 3)
        #expect(store.state.currentSelectionCount == 3)
    }

    @Test func 레이아웃_용량이_가득차면_추가_선택이_불가능함() {
        let store = makeSUT() // 기본 레이아웃: oneByOne (capacity 1)
        store.send(.selectPhoto(0))

        store.send(.selectPhoto(1))

        #expect(store.state.photos[1].selectNumber == nil)
        #expect(store.state.currentSelectionCount == 1)
    }

    // MARK: - 사진 선택 해제

    @Test func 선택된_사진을_다시_선택하면_선택이_해제됨() {
        let store = makeSUT()
        store.send(.selectPhoto(0))

        store.send(.selectPhoto(0))

        #expect(store.state.photos[0].selectNumber == nil)
        #expect(store.state.selectedPhotos.isEmpty)
        #expect(store.state.currentSelectionCount == 0)
    }

    @Test func 중간_사진을_선택_해제하면_뒤의_선택번호가_재정렬됨() {
        let store = makeSUT()
        store.reduce(.setLayout(.twoByTwo)) // capacity 4
        store.send(.selectPhoto(0)) // selectNumber = 1
        store.send(.selectPhoto(1)) // selectNumber = 2
        store.send(.selectPhoto(2)) // selectNumber = 3

        store.send(.selectPhoto(1)) // 2번 해제

        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.photos[1].selectNumber == nil)
        #expect(store.state.photos[2].selectNumber == 2)
        #expect(store.state.selectedPhotos.count == 2)
        #expect(store.state.currentSelectionCount == 2)
    }

    // MARK: - 레이아웃 변경

    @Test func 레이아웃을_변경하면_선택된_레이아웃이_변경됨() {
        let store = makeSUT()

        store.send(.selectLayout(.twoByTwo))

        #expect(store.state.selectedLayout == .twoByTwo)
    }

    @Test func 레이아웃_용량이_줄어들면_초과된_사진의_선택이_해제됨() {
        let store = makeSUT()
        store.reduce(.setLayout(.twoByTwo)) // capacity 4
        store.send(.selectPhoto(0))
        store.send(.selectPhoto(1))
        store.send(.selectPhoto(2))
        store.send(.selectPhoto(3)) // 4개 선택

        store.send(.selectLayout(.twoByOne)) // capacity 2로 변경

        #expect(store.state.currentSelectionCount == 2)
        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.photos[1].selectNumber == 2)
        #expect(store.state.photos[2].selectNumber == nil)
        #expect(store.state.photos[3].selectNumber == nil)
    }

    @Test func 레이아웃_용량이_늘어나면_기존_선택이_유지됨() {
        let store = makeSUT()
        store.send(.selectPhoto(0)) // 1개 선택 (oneByOne)

        store.send(.selectLayout(.twoByTwo)) // capacity 4로 변경

        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.currentSelectionCount == 1)
    }

    @Test func 레이아웃_용량_이하로_선택된_경우_변경해도_선택이_유지됨() {
        let store = makeSUT()
        store.reduce(.setLayout(.twoByTwo)) // capacity 4
        store.send(.selectPhoto(0))
        store.send(.selectPhoto(1)) // 2개 선택

        store.send(.selectLayout(.twoByOne)) // capacity 2로 변경

        #expect(store.state.photos[0].selectNumber == 1)
        #expect(store.state.photos[1].selectNumber == 2)
        #expect(store.state.currentSelectionCount == 2)
    }

    // MARK: - 프레임 변경

    @Test func 프레임을_변경하면_선택된_프레임이_변경됨() {
        let store = makeSUT()

        store.send(.selectFrame(.white))

        #expect(store.state.selectedFrame == .white)
    }

    // MARK: - 완료 버튼 상태

    @Test func 선택_개수가_용량보다_적으면_완료_버튼이_비활성화됨() {
        let store = makeSUT() // oneByOne, capacity 1, 0개 선택

        #expect(store.state.isCompletedButtonDisabled == true)
    }

    @Test func 선택_개수가_용량과_같으면_완료_버튼이_활성화됨() {
        let store = makeSUT() // oneByOne, capacity 1
        store.send(.selectPhoto(0))

        #expect(store.state.isCompletedButtonDisabled == false)
    }
}
