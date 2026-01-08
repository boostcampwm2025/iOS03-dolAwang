//
//  StoreProtocol.swift
//  mirroringBooth
//
//  Created by 이상유 on 2026-01-06.
//

protocol StoreProtocol: AnyObject {
    associatedtype State
    associatedtype Intent
    associatedtype Result

    var state: State { get }

    func action(_ intent: Intent) -> [Result]
    func reduce(_ result: Result)
}

extension StoreProtocol {
    func send(_ intent: Intent) {
        let results = action(intent)
        for result in results {
            reduce(result)
        }
    }
}
