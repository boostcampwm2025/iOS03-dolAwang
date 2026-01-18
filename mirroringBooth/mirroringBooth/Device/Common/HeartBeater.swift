//
//  HeartBeater.swift
//  mirroringBooth
//
//  Created by Liam on 1/18/26.
//

import Foundation
import OSLog

final class HeartBeater {
    private var lastHeartbeat: Date?
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "mirroringBooth.HeartBeater", qos: .utility)
    let repeatInterval: TimeInterval
    let timeout: TimeInterval
    let onTimeout: () -> Void

    /// 반복 시간, 타임아웃
    init(
        repeatInterval: TimeInterval,
        timeout: TimeInterval,
        onTimeout: @escaping () -> Void
    ) {
        self.repeatInterval = repeatInterval
        self.timeout = timeout
        self.onTimeout = onTimeout
    }

    deinit {
        stop()
    }

    func start() {
        // 기존 타이머가 존재하면 정상적으로 제거 후 재시작
        stop()
        lastHeartbeat = Date()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: repeatInterval)
        timer?.setEventHandler { [weak self] in
            self?.checkAlive()
        }
        timer?.resume()
        Logger.heartBeater.debug("Heartbeat timer started (interval:\(self.repeatInterval)s, timeout:\(self.timeout)s)")
    }

    func stop() {
        timer?.cancel()
        timer = nil
        lastHeartbeat = nil
        Logger.heartBeater.debug("Heartbeat stopped")
    }

    func beat() {
        queue.async { [weak self] in
            self?.lastHeartbeat = Date()
        }
    }

    // 타임아웃 확인
    private func checkAlive() {
        guard let lastHeartbeat else {
            stop()
            return
        }
        Logger.heartBeater.debug("\(Date().timeIntervalSince(lastHeartbeat))")
        if Date().timeIntervalSince(lastHeartbeat) > self.timeout {
            Logger.heartBeater.warning("Heartbeat timed out")
            stop()
            onTimeout()
        }
    }
}
