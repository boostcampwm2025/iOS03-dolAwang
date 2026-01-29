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
        case connect
        case prepare
        case connectAck
        case disconnect
        case captureComplete
        case checkIfCaptureAvailable
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
    private var shouldPrepareToCapture: Bool = false

    var onReachableChanged: ((Bool) -> Void)?

    var onReceiveConnectionCompleted: (() -> Void)?

    var onReceiveRequestToPrepare: (() -> Void)?

    var onReceiveCaptureComplete: (() -> Void)?

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
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 활성화할 수 없습니다.")
            return
        }

        session.delegate = self

        // iPhone에게 Watch 앱이 active 상태임을 전달
        pushWatchAppState(.active)

        if session.activationState == .activated {
            self.logger.info("WCSession이 이미 활성화되어 있습니다.")

            // 이미 활성화된 경우에도 현재 상태를 확인하여 콜백 호출
            let context: [String: Any] = session.receivedApplicationContext
            handleAppStateUpdate(context)
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

        // iPhone에게 연결 끊김 상태 전달
        pushWatchAppState(.inactive)

        // 내부 연결 끊김 상태 전달
        Task { @MainActor in
            self.onReachableChanged?(false)
        }
        self.logger.info("WCSession 연결 대기 중지")
    }

    /// iPhone에게 Watch 앱 상태를 전달합니다.
    private func pushWatchAppState(_ state: AppStateValue) {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 상태를 푸시할 수 없습니다.")
            return
        }

        do {
            try session.updateApplicationContext([MessageKey.appState.rawValue: state.rawValue])
            self.logger.info("Watch 앱 상태 푸시: \(state.rawValue)")
        } catch {
            self.logger.error("Watch 앱 상태 푸시 실패: \(error.localizedDescription)")
        }
    }

    private func sendMessage(
        action: ActionValue,
        rejectedActionString: String
    ) {
        guard let session = self.session else {
            self.logger.error("WCSession이 지원되지 않아 \(rejectedActionString)")
            return
        }

        guard session.isReachable else {
            self.logger.error("아이폰에 도달할 수 없어 \(rejectedActionString)")
            return
        }

        let message = [MessageKey.action.rawValue: action.rawValue]
        session.sendMessage(message, replyHandler: nil)
    }

    /// 카메라 캡쳐 요청을 iPhone로 전송합니다.
    func sendCaptureRequest() async {
        self.sendMessage(
            action: .capture,
            rejectedActionString: "카메라 캡처 요청을 보낼 수 없습니다."
        )
    }

    /// 연결 요청에 대한 응답을 iPhone으로 전송합니다.
    private func sendConnectionAck() {
        self.sendMessage(
            action: .connectAck,
            rejectedActionString: "연결 완료 응답을 보낼 수 없습니다."
        )
    }

    /// 촬영 준비를 해야하는지 확인해줄 것을 iPhone으로 전송합니다.
    private func sendCheckCaptureAvailabilityRequest() {
        self.sendMessage(
            action: .checkIfCaptureAvailable,
            rejectedActionString: "촬영 준비 여부 확인 요청을 보낼 수 없습니다."
        )
    }

    private nonisolated func handleAppStateUpdate(_ applicationContext: [String: Any]) {
        let appStateRawValue = applicationContext[MessageKey.appState.rawValue] as? String
        let appStateValue = appStateRawValue.flatMap { AppStateValue(rawValue: $0) }

        let reachable: Bool = (appStateValue == .active)

        Task { @MainActor in
            self.lastAppState = appStateValue ?? .terminated
            self.onReachableChanged?(reachable)
        }
    }

}

extension WatchConnectionManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        self.logger.info("WCSession applicationContext 수신: \(applicationContext)")
        handleAppStateUpdate(applicationContext)
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
        handleAppStateUpdate(context)
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        self.logger.info("WCSession 도달 가능 여부 변경: \(session.isReachable)")

        Task { @MainActor in
            if self.lastAppState == .active {
                if !shouldPrepareToCapture {
                    sendCheckCaptureAvailabilityRequest()
                }
                self.onReachableChanged?(session.isReachable)
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        self.logger.info("WCSession 메시지 수신: \(message)")
        let actionValue: String? = message[MessageKey.action.rawValue] as? String

        if actionValue == ActionValue.connect.rawValue {
            self.logger.info("연결 완료 알림 수신됨.")
            Task { @MainActor in
                self.sendConnectionAck()
                self.onReceiveConnectionCompleted?()
            }
        } else if actionValue == ActionValue.prepare.rawValue {
            self.logger.info("촬영 준비 요청 수신됨.")
            Task { @MainActor in
                shouldPrepareToCapture = true
                self.onReceiveRequestToPrepare?()
            }
        } else if actionValue == ActionValue.disconnect.rawValue {
            self.logger.info("연결 해제 요청 수신됨.")
            Task { @MainActor in
                self.onReachableChanged?(false)
            }
        } else if actionValue == ActionValue.captureComplete.rawValue {
            self.logger.info("모든 촬영 완료 수신됨.")
            Task { @MainActor in
                self.onReceiveCaptureComplete?()
            }
        }
    }

}
#endif
