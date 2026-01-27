//
//  ResultStore.swift
//  mirroringBooth
//
//  Created by Liam on 1/26/26.
//

import OSLog
import UIKit

@Observable
final class ResultStore: StoreProtocol {
    struct State {
        // Photo Information
        var resultPhoto: PhotoInformation

        // home alert
        var showHomeAlert: Bool = false

        // toast
        var showSavedToast: Bool = false
        var toastMessage: String = ""

        // fileExporter
        var showFileExporter: Bool = false
        var document: ImageDocument?

        // result image
        var renderedImage: UIImage?

        // scale
        var scale: CGFloat = 1
        var lastScale: CGFloat = 1

        // share sheet
        var showShareSheet: Bool = false
        var shareItems: [Any] = []
    }

    enum Intent {
        case showHomeAlert(Bool)
        case showSavedToast(Bool, message: String? = nil)
        case showFileExporter(Bool, document: ImageDocument? = nil)
        case setRenderedImage(image: UIImage)
        case setScale(scale: CGFloat)
        case setLastScale(scale: CGFloat)

        case showShareSheet(Bool)
        case prepareShare(UIImage)
    }

    enum Result {
        case setShowHomeAlert(Bool)

        case setShowSavedToast(Bool, message: String? = nil)
        case setShowFileExporter(Bool, document: ImageDocument? = nil)
        case setRenderedImage(UIImage)

        case setScale(CGFloat)
        case setLastScale(CGFloat)

        case setShowShareSheet(Bool)
        case setShareItems([Any])
    }

    private(set) var state: State

    init(resultPhoto: PhotoInformation) {
        self.state = State(resultPhoto: resultPhoto)
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .showHomeAlert(let bool):
            return [.setShowHomeAlert(bool)]
        case .showSavedToast(let bool, let message):
            return [.setShowSavedToast(bool, message: message)]
        case .showFileExporter(let bool, let document):
            return [.setShowFileExporter(bool, document: document)]
        case .showShareSheet(let bool):
            return [.setShowShareSheet(bool)]
        case .setRenderedImage(let image):
            saveResultImage(image)
            return [.setRenderedImage(image)]
        case .setScale(let scale):
            return [.setScale(scale)]
        case .setLastScale(let scale):
            return [.setLastScale(scale)]
        case .prepareShare(let image):
            return [
                .setShareItems([image]),
                .setShowShareSheet(true)
            ]
        }
    }

    @MainActor
    func reduce(_ result: Result) {
        switch result {
        case .setShowHomeAlert(let bool):
            state.showHomeAlert = bool
        case .setShowSavedToast(let bool, let message):
            var newState = self.state
            newState.toastMessage = message ?? ""
            newState.showSavedToast = bool
            self.state = newState
        case .setShowFileExporter(let bool, let document):
            var newState = self.state
            newState.document = document
            newState.showFileExporter = bool
            self.state = newState
        case .setRenderedImage(let image):
            state.renderedImage = image
        case .setShowShareSheet(let bool):
            state.showShareSheet = bool
            if !bool {
                // 공유 시트가 닫힐 때 shareItems 비우기
                state.shareItems = []
            }
        case .setShareItems(let items):
            state.shareItems = items
        case .setScale(let scale):
            state.scale = scale
        case .setLastScale(let lastScale):
            state.lastScale = lastScale
        }
    }

    private func saveResultImage(_ image: UIImage) {
        Task {
            do {
                try await PhotoCacheManager.shared.saveResultImage(image)
            } catch {
                Logger.resultStore.error("Failed to cache result image: \(error)")
            }
        }
    }
}
