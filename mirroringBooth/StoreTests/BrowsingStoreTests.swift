//
//  BrowsingStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Testing
@testable import mirroringBooth

@MainActor
struct BrowsingStoreTests {

    // MARK: - Helper

    private func makeSUT() -> BrowsingStore {
        BrowsingStore(Browser(), WatchConnectionManager())
    }

    private func makeDevice(
        id: String = "TestDevice",
        type: DeviceType = .iPhone
    ) -> NearbyDevice {
        NearbyDevice(id: id, type: type)
    }

    // MARK: - 기기 탐색

    @Test func 기기가_사라지면_목록에서_제거됨() {
        let store = makeSUT()
        let device = makeDevice()
        store.reduce(.addDiscoveredDevice(device))

        store.reduce(.removeDiscoveredDevice(device))

        #expect(store.state.discoveredDevices.isEmpty)
    }

    @Test func 같은_기기가_다시_발견되면_중복_추가되지_않고_업데이트됨() {
        let store = makeSUT()
        let device = makeDevice()

        store.reduce(.addDiscoveredDevice(device))
        store.reduce(.addDiscoveredDevice(device))

        #expect(store.state.discoveredDevices.count == 1)
    }

    // MARK: - 미러링 기기 연결 시 토스트

    @Test func 미러링_기기가_연결되면_토스트에_기기_이름이_표시됨() {
        let store = makeSUT()

        store.reduce(.setMirroringDevice(makeDevice(id: "MyiPad")))

        #expect(store.state.showToast == true)
        #expect(store.state.toastMessage.contains("MyiPad"))
    }

    // MARK: - 기기 연결 시도

    @Test func 기기에_연결을_시도하면_연결중_상태가_됨() {
        let store = makeSUT()

        store.reduce(.setIsConnecting(true))

        #expect(store.state.isConnecting == true)
    }

    // MARK: - 탐색 화면 진입

    @Test func 탐색_화면에_진입하면_애니메이션이_시작됨() {
        let store = makeSUT()

        store.reduce(.startAnimation)

        #expect(store.state.animationTrigger == true)
    }

    // MARK: - hasSelectedDevice

    @Test func 현재_타겟에_맞는_기기가_있어야_선택된_것으로_판단() {
        let store = makeSUT()

        // 미러링 타겟 — 미러링 기기 없으면 false
        #expect(store.state.hasSelectedDevice == false)

        // 미러링 타겟 — 미러링 기기 있으면 true
        store.reduce(.setMirroringDevice(makeDevice()))
        #expect(store.state.hasSelectedDevice == true)

        // 리모트 타겟 — 리모트 기기 없으면 false
        store.reduce(.setCurrentTarget(.remote))
        #expect(store.state.hasSelectedDevice == false)

        // 리모트 타겟 — 리모트 기기 있으면 true
        store.reduce(.setRemoteDevice(makeDevice(id: "Watch", type: .watch)))
        #expect(store.state.hasSelectedDevice == true)
    }
}
