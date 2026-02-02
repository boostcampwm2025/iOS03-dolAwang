//
//  ResultStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Testing
import UIKit
@testable import mirroringBooth

@MainActor
struct ResultStoreTests {

    // MARK: - Helper

    private func makeSUT() -> ResultStore {
        let photo = PhotoInformation(
            layout: .oneByOne,
            frame: .black,
            photos: []
        )
        return ResultStore(resultPhoto: photo)
    }

    // MARK: - 홈으로 돌아가기

    @Test func 홈_버튼을_누르면_홈_이동_확인_알림이_표시됨() {
        let store = makeSUT()

        store.send(.showHomeAlert(true))
        #expect(store.state.showHomeAlert == true)
    }

    // MARK: - 사진 저장

    @Test func 사진을_저장하면_저장_완료_토스트가_메시지와_함께_표시됨() {
        let store = makeSUT()

        store.send(.showSavedToast(true, message: "저장 완료"))

        #expect(store.state.showSavedToast == true)
        #expect(store.state.toastMessage == "저장 완료")
    }

    @Test func 저장_토스트가_사라지면_메시지가_초기화됨() {
        let store = makeSUT()
        store.send(.showSavedToast(true, message: "저장 완료"))

        store.send(.showSavedToast(false))

        #expect(store.state.showSavedToast == false)
        #expect(store.state.toastMessage == "")
    }

    // MARK: - 파일로 내보내기

    @Test func 파일로_내보내기를_누르면_내보내기_화면이_표시됨() {
        let store = makeSUT()
        let document = ImageDocument(image: UIImage())

        store.send(.showFileExporter(true, document: document))

        #expect(store.state.showFileExporter == true)
        #expect(store.state.document != nil)
    }

    @Test func 내보내기_화면을_닫으면_문서가_초기화됨() {
        let store = makeSUT()
        let document = ImageDocument(image: UIImage())
        store.send(.showFileExporter(true, document: document))

        store.send(.showFileExporter(false))

        #expect(store.state.showFileExporter == false)
        #expect(store.state.document == nil)
    }

    // MARK: - 결과 이미지 렌더링

    @Test func 결과_이미지가_렌더링되면_화면에_표시됨() {
        let store = makeSUT()
        let image = UIImage()

        store.send(.setRenderedImage(image: image))

        #expect(store.state.renderedImage != nil)
    }

    // MARK: - 핀치 줌

    @Test func 사진을_핀치하면_확대_비율이_변경됨() {
        let store = makeSUT()

        store.send(.setScale(scale: 2.5))

        #expect(store.state.scale == 2.5)
    }

    @Test func 핀치를_놓으면_마지막_확대_비율이_저장됨() {
        let store = makeSUT()

        store.send(.setLastScale(scale: 1.5))

        #expect(store.state.lastScale == 1.5)
    }

    // MARK: - 공유

    @Test func 공유_버튼을_누르면_공유_시트가_표시됨() {
        let store = makeSUT()

        store.send(.showShareSheet(true))
        #expect(store.state.showShareSheet == true)
    }
}
