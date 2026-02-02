//
//  RootStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Testing
@testable import mirroringBooth

@MainActor
struct RootStoreTests {

    // MARK: - 타임아웃 알럿

    @Test func 타임아웃_알럿이_보여야_할_때() {
        let store = RootStore()

        store.send(.showTimeoutAlert(true))

        #expect(store.state.showTimeoutAlert == true)
    }

    @Test func 타임아웃_알럿을_닫았을_때() {
        let store = RootStore()
        store.send(.showTimeoutAlert(true))

        store.send(.showTimeoutAlert(false))

        #expect(store.state.showTimeoutAlert == false)
    }

    // MARK: - 연결 해제

    @Test func 연결을_모두_해제할_때_advertiser가_정리됨() {
        let store = RootStore()
        store.advertiser = Advertiser(photoCacheManager: .shared)

        store.send(.disconnect)

        #expect(store.advertiser == nil)
    }

    @Test func 연결을_모두_해제할_때_browser가_정리됨() {
        let store = RootStore()
        store.browser = Browser()

        store.send(.disconnect)

        #expect(store.browser == nil)
    }

    @Test func 연결이_없는_상태에서_해제해도_문제없음() {
        let store = RootStore()

        store.send(.disconnect)

        #expect(store.advertiser == nil)
        #expect(store.browser == nil)
    }
}
