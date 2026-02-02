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
        var resultPhoto: PhotoInformation?
        var renderedImage: UIImage?
        var scale: CGFloat = 1
        var lastScale: CGFloat = 1

        var showFileExporter: Bool = false
        var document: ImageDocument?

        var showHomeAlert: Bool = false
        var showSettingAlert: Bool = false
        var showSavedToast: Bool = false
        var toastMessage: String = ""
        var showShareSheet: Bool = false
    }

    enum Intent {
        case setRenderedImage(image: UIImage)
        case setScale(scale: CGFloat)
        case setLastScale(scale: CGFloat)
        case showFileExporter(Bool, document: ImageDocument? = nil)

        case showHomeAlert(Bool)
        case showSettingAlert(Bool)
        case showSavedToast(Bool, message: String? = nil)
        case showShareSheet(Bool)
    }

    enum Result {
        case setRenderedImage(UIImage)
        case setScale(CGFloat)
        case setLastScale(CGFloat)
        case setShowFileExporter(Bool, document: ImageDocument? = nil)

        case setShowHomeAlert(Bool)
        case setShowSettingAlert(Bool)
        case setShowSavedToast(Bool, message: String? = nil)
        case setShowShareSheet(Bool)
    }

    private(set) var state: State

    init(resultPhoto: PhotoInformation) {
        self.state = State(resultPhoto: resultPhoto)
    }

    init(image: UIImage) {
        self.state = State(resultPhoto: nil, renderedImage: image)
        Task { await PhotoCacheManager.shared.clearCache() }
    }

    func action(_ intent: Intent) -> [Result] {
        switch intent {
        case .setRenderedImage(let image):
            return [.setRenderedImage(image)]

        case .setScale(let scale):
            return [.setScale(scale)]

        case .setLastScale(let scale):
            return [.setLastScale(scale)]

        case .showFileExporter(let bool, let document):
            return [.setShowFileExporter(bool, document: document)]

        case .showHomeAlert(let bool):
            return [.setShowHomeAlert(bool)]

        case .showSettingAlert(let bool):
            saveResultImage(state.renderedImage ?? UIImage())
            return [.setShowSettingAlert(bool)]

        case .showSavedToast(let bool, let message):
            return [.setShowSavedToast(bool, message: message)]

        case .showShareSheet(let bool):
            return [.setShowShareSheet(bool)]
        }
    }

    @MainActor
    func reduce(_ result: Result) {
        var state = self.state

        switch result {
        case .setRenderedImage(let image):
            state.renderedImage = image

        case .setScale(let scale):
            state.scale = scale

        case .setLastScale(let lastScale):
            state.lastScale = lastScale

        case .setShowFileExporter(let bool, let document):
            state.document = document
            state.showFileExporter = bool

        case .setShowHomeAlert(let bool):
            state.showHomeAlert = bool

        case .setShowSettingAlert(let bool):
            state.showSettingAlert = bool

        case .setShowSavedToast(let bool, let message):
            state.toastMessage = message ?? ""
            state.showSavedToast = bool

        case .setShowShareSheet(let bool):
            state.showShareSheet = bool
        }

        self.state = state
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
