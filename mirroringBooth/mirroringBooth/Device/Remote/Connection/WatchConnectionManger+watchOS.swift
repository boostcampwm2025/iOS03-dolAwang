//
//  WatchConnectionManger+watchOS.swift
//  mirroringBoothWatch
//
//  Created by 최윤진 on 1/8/26.
//

#if os(watchOS)
import Foundation
import OSLog
import WatchConnectivity

final class WatchConnectionManager: NSObject {
    private enum ActionValue: String {
        case capture
    }

    private enum MessageKey: String {
        case action
        case appState
    }

    private enum AppStateValue: String {
        case active
        case inactive
        case background
        case terminated
    }

    private let session: WCSession?
    private let logger = Logger.watchConnectionManager
    private var lastAppState: AppStateValue = .terminated

    var onReachableChanged: ((Bool) -> Void)?

    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
            self.logger.info("WCSession이 지원됩니다.")
        } else {
            self.session = nil
            self.logger.warning("WCSession이 지원되지 않습니다.")
        }

        super.init()

        self.session?.delegate = self
        self.logger.info("WatchConnectionManager(watchOS)가 초기화되었습니다.")
    }

    /// WCSession 활성화를 시작합니다.
    func start() {
        Task { @MainActor in
            self.onReachableChanged?(false)
        }
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 활성화할 수 없습니다.")
            return
        }
        session.delegate = self

        if session.activationState == .activated {
            self.logger.info("WCSession이 이미 활성화되어 있습니다.")
            return
        }

        session.activate()
        self.logger.info("WCSession 활성화를 시작합니다.")
    }

    func stop() {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 비활성화할 수 없습니다.")
            return
        }
        session.delegate = nil
        self.logger.info("WCSession이 비활성화되었습니다.")
    }

    /// 카메라 캡쳐 요청을 상대 기기로 전송합니다.
    func sendCaptureRequest() async {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 활성화할 수 없습니다.")
            return
        }

        let message: [String: Any] = [MessageKey.action.rawValue: ActionValue.capture.rawValue]

        guard session.isReachable else {
            self.logger.error("WCSession이 도달할 수 없어 메시지를 보낼 수 없습니다.")
            return
        }

        session.sendMessage(
            message,
            replyHandler: nil
        )
    }
}

extension WatchConnectionManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        self.logger.info("WCSession applicationContext 수신: \(applicationContext)")

        let appStateRawValue = applicationContext[MessageKey.appState.rawValue] as? String
        let appStateValue = appStateRawValue.flatMap { AppStateValue(rawValue: $0) }

        let reachable: Bool
        switch appStateValue {
        case .active:
            reachable = true
        case .inactive, .background, .terminated, .none:
            reachable = false
        }

        Task { @MainActor in
            self.lastAppState = appStateValue ?? .terminated
            self.onReachableChanged?(reachable)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error: Error = error {
            self.logger.error("WCSession 활성화 실패: 오류=\(error.localizedDescription)")
        } else {
            self.logger.info("WCSession 활성화 성공")
        }

        let context: [String: Any] = session.receivedApplicationContext
        let appStateRawValue: String? = context[MessageKey.appState.rawValue] as? String
        let appStateValue: AppStateValue? = appStateRawValue.flatMap { AppStateValue(rawValue: $0) }

        let reachable: Bool = (appStateValue == .active)

        Task { @MainActor in
            self.lastAppState = appStateValue ?? .terminated
            self.onReachableChanged?(reachable)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        self.logger.info("WCSession 도달 가능 여부 변경: \(session.isReachable)")

        Task { @MainActor in
            if self.lastAppState == .active {
                self.onReachableChanged?(session.isReachable)
            }
        }
    }
}
#endif
