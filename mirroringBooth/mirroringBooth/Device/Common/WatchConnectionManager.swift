//
//  WatchConnectionManager.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/6/26.
//

#if os(iOS)
import UIKit
#endif
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
    var onReceiveMessage: (([String: Any]) -> Void)?

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
        self.logger.info("WatchConnectionManager가 초기화되었습니다.")
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
    func sendCaptureRequest() async throws {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 활성화할 수 없습니다.")
            throw NSError(
                domain: "WatchConnectionManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WCSession not supported"]
            )
        }

        let message: [String: Any] = [MessageKey.action.rawValue: ActionValue.capture.rawValue]

        guard session.isReachable else {
            self.logger.error("WCSession이 도달할 수 없어 메시지를 보낼 수 없습니다.")
            throw NSError(
                domain: "WatchConnectionManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "WCSession is not reachable"]
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.sendMessage(
                message,
                replyHandler: { _ in
                    continuation.resume()
                },
                errorHandler: { error in
                    continuation.resume(throwing: error)
                }
            )
        }
    }
}

extension WatchConnectionManager {
    #if os(iOS)
    func pushIOSAppState(state: UIApplication.State) {
        guard let session: WCSession = self.session else {
            self.logger.error("WCSession이 지원되지 않아 상태를 푸시할 수 없습니다.")
            return
        }

        let appState: AppStateValue
        switch state {
        case .active:
            appState = .active
        case .inactive:
            appState = .inactive
        case .background:
            appState = .background
        @unknown default:
            appState = .inactive
        }

        do {
            try session.updateApplicationContext([MessageKey.appState.rawValue: appState.rawValue])
            self.logger.info("iPhone 앱 상태 푸시: \(appState.rawValue)")
        } catch {
            self.logger.error("iPhone 앱 상태 푸시 실패: \(error.localizedDescription)")
        }
    }
    #endif
}

// MARK: - For Watch Only
extension WatchConnectionManager: WCSessionDelegate {
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        self.logger.info("WCSession 비활성화됨.")
        Task { @MainActor in
            self.onReachableChanged?(false)
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        self.logger.info("WCSession 비활성화 후 재활성화합니다.")
        session.activate()
        Task { @MainActor in
            self.onReachableChanged?(false)
        }
    }
    #endif

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
        if let error = error {
            self.logger.error("WCSession 활성화 실패: 오류=\(error.localizedDescription)")
        } else {
            self.logger.info("WCSession 활성화 성공")
        }

        #if os(watchOS)
        let context = session.receivedApplicationContext
        let appStateRawValue = context[MessageKey.appState.rawValue] as? String
        let appStateValue = appStateRawValue.flatMap { AppStateValue(rawValue: $0) }

        let reachable = (appStateValue == .active)

        Task { @MainActor in
            self.lastAppState = appStateValue ?? .terminated
            self.onReachableChanged?(reachable)
        }
        #endif
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        self.logger.info("WCSession 도달 가능 여부 변경: \(session.isReachable)")
        #if os(iOS)
        Task { @MainActor in
            self.onReachableChanged?(session.isReachable)
        }
        #endif

        #if os(watchOS)
        Task { @MainActor in
            if self.lastAppState == .active {
                self.onReachableChanged?(session.isReachable)
            }
        }
        #endif
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        self.logger.info("WCSession 메시지 수신: \(message)")
        Task { @MainActor in
            self.onReceiveMessage?(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        self.logger.info("WCSession 메시지 수신(reply 요청): \(message)")

        replyHandler([:])

        let actionValue: String? = message[MessageKey.action.rawValue] as? String
        if actionValue == ActionValue.capture.rawValue {
            self.logger.info("캡쳐 요청 수신됨.")
        }

        Task { @MainActor in
            self.onReceiveMessage?(message)
        }
    }
}
