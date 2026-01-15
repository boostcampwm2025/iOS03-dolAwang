//
//  WatchConnectionManager+iOS.swift
//  mirroringBooth
//
//  Created by 최윤진 on 1/8/26.
//

#if os(iOS)
import OSLog
import UIKit
import WatchConnectivity

final class WatchConnectionManager: NSObject {
    private enum ActionValue: String {
        case capture
        case connect
        case prepare
        case connectAck
        case disconnect
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

    var onReachableChanged: ((Bool) -> Void)?
    var onReceiveCaptureRequest: (() -> Void)?
    var onReceiveConnectionAck: (() -> Void)?

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
        self.logger.info("WatchConnectionManager(iOS)가 초기화되었습니다.")
    }

    /// WCSession 활성화를 시작합니다.
    func start() {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 활성화할 수 없습니다.")
            return
        }
        session.delegate = self

        if session.activationState == .activated {
            self.logger.info("WCSession이 이미 활성화되어 있습니다.")

            // 이미 활성화된 경우 현재 reachable 상태를 확인하여 콜백 호출
            Task { @MainActor in
                self.onReachableChanged?(session.isReachable)
            }
            return
        }

        session.activate()
        self.logger.info("WCSession 활성화를 시작합니다.")
    }

    func stop() {
        guard self.session != nil else {
            self.logger.error("WCSession이 지원되지 않아 비활성화할 수 없습니다.")
            return
        }

        // delegate를 nil로 설정하지 말고, 연결 끊김 상태만 전달
        Task { @MainActor in
            self.onReachableChanged?(false)
        }
        self.logger.info("WCSession 연결 대기 중지")
    }

    func pushIOSAppState(state: UIApplication.State) {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 상태를 푸시할 수 없습니다.")
            return
        }

        let appState: AppStateValue
        switch state {
        case .active: appState = .active
        case .background: appState = .background
        default: appState = .inactive
        }

        do {
            try session.updateApplicationContext([MessageKey.appState.rawValue: appState.rawValue])
            self.logger.info("iPhone 앱 상태 푸시: \(appState.rawValue)")
        } catch {
            self.logger.error("iPhone 앱 상태 푸시 실패: \(error.localizedDescription)")
        }
    }

    private func sendMessage(
        action: ActionValue,
        rejectedActionString: String,
        successLog: String? = nil
    ) {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 \(rejectedActionString)")
            return
        }

        guard session.isReachable else {
            self.logger.error("워치에 도달할 수 없어 \(rejectedActionString)")
            return
        }

        let message = [MessageKey.action.rawValue: action.rawValue]
        session.sendMessage(message, replyHandler: nil)

        if let successLog = successLog {
            self.logger.info("\(successLog)")
        }
    }

    // 워치에 연결 요청을 전송
    func sendConnectionRequest() {
        self.sendMessage(
            action: .connect,
            rejectedActionString: "연결 요청을 보낼 수 없습니다."
        )
    }

    // 촬영 기기와 미러링 기기에서 촬영을 시작할 때 워치에게도 알림
    func prepareWatchToCapture() {
        self.sendMessage(
            action: .prepare,
            rejectedActionString: "촬영 준비 요청을 보낼 수 없습니다."
        )
    }

    // 워치에게 연결 해제를 알림
    func sendDisconnectionNotification() {
        self.sendMessage(
            action: .disconnect,
            rejectedActionString: "연결 해제 요청을 보낼 수 없습니다.",
            successLog: "워치에 연결 해제 알림 전송"
        )
    }

    // 워치에 연결 해제 요청을 전송
    func sendDisconnectRequest() {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 워치에 연결 해제를 알릴 수 없습니다.")
            return
        }

        guard session.isReachable else {
            self.logger.error("워치에 도달할 수 없어 연결 해제 요청을 보낼 수 없습니다.")
            return
        }

        let message = [MessageKey.action.rawValue: ActionValue.disconnect.rawValue]
        session.sendMessage(message, replyHandler: nil)
        self.logger.info("워치에 연결 해제 요청 전송")
    }
}

extension WatchConnectionManager: WCSessionDelegate {
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
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        self.logger.info("WCSession applicationContext 수신: \(applicationContext)")
        handleWatchReachability(session: session)
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        self.logger.info("WCSession 도달 가능 여부 변경: \(session.isReachable)")
        handleWatchReachability(session: session)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        self.logger.info("WCSession 메시지 수신: \(message)")
        let actionValue: String? = message[MessageKey.action.rawValue] as? String

        if actionValue == ActionValue.capture.rawValue {
            self.logger.info("캡쳐 요청 수신됨.")
            Task { @MainActor in
                self.onReceiveCaptureRequest?()
            }
        } else if actionValue == ActionValue.connectAck.rawValue {
            self.logger.info("워치 연결 응답 수신됨.")
            Task { @MainActor in
                self.onReceiveConnectionAck?()
            }
        }
    }

    private nonisolated func handleWatchReachability(session: WCSession) {
        let context = session.receivedApplicationContext
        let appStateRawValue = context[MessageKey.appState.rawValue] as? String
        let appStateValue = appStateRawValue.flatMap { AppStateValue(rawValue: $0) }

        let reachable = (appStateValue == .active) && session.isReachable

        Task { @MainActor in
            self.onReachableChanged?(reachable)
        }
    }
}
#endif
