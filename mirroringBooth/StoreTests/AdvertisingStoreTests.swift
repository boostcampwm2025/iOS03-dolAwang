//
//  AdvertisingStoreTests.swift
//  StoreTests
//
//  Created by 이상유 on 2026-02-02.
//

import Testing
@testable import mirroringBooth

@MainActor
struct AdvertisingStoreTests {
    
    // MARK: - Helper
    
    private func makeSUT() -> AdvertisingStore {
        let advertiser = Advertiser(photoCacheManager: PhotoCacheManager.shared)
        return AdvertisingStore(advertiser)
    }
    
    // MARK: - 화면 진입 (onAppear)
    
    @Test func 화면에_진입하면_네비게이션_상태가_초기화됨() {
        let store = makeSUT()
        
        store.send(.entry)
        
        #expect(store.state.onNavigate == false)
        #expect(store.state.deviceUseType == nil)
    }
    
    // MARK: - 연결 성공 (connected)
    
    @Test func 연결되면_연결_상태가_true로_변경됨() {
        let store = makeSUT()
        
        store.send(.connected)
        
        #expect(store.state.isConnected == true)
    }
    
    // MARK: - 화면 퇴장 (exit)
    
    @Test func 퇴장해도_상태에_영향_없음() {
        let store = makeSUT()
        
        store.send(.exit)
        
        #expect(store.state.isConnected == false)
        #expect(store.state.onNavigate == false)
    }
    
    // MARK: - reduce 테스트 (콜백으로 발생하는 Result)
    
    @Test func 네비게이션이_설정됨() {
        let store = makeSUT()
        
        store.reduce(.setOnNavigate(true, type: .mirroring))
        
        #expect(store.state.onNavigate == true)
        #expect(store.state.deviceUseType == .mirroring)
    }
    
    @Test func 네비게이션을_닫으면_타입이_초기화됨() {
        let store = makeSUT()
        store.reduce(.setOnNavigate(true, type: .mirroring))
        
        store.reduce(.setOnNavigate(false, type: nil))
        
        #expect(store.state.onNavigate == false)
        #expect(store.state.deviceUseType == nil)
    }
    
    @Test func 리모트_선택_상태가_반영됨() {
        let store = makeSUT()
        
        store.reduce(.setIsRemoteSelected(true))
        
        #expect(store.state.isRemoteSelected == true)
    }
    
    // MARK: - 콜백 시나리오 (navigateToSelectModeCommandCallBack)
    
    @Test func 촬영모드_선택_콜백_시_리모트_활성화와_함께_네비게이션됨() {
        let store = makeSUT()
        
        store.reduce(.setIsRemoteSelected(true))
        store.reduce(.setOnNavigate(true, type: .mirroring))
        
        #expect(store.state.isRemoteSelected == true)
        #expect(store.state.onNavigate == true)
        #expect(store.state.deviceUseType == .mirroring)
    }
}
