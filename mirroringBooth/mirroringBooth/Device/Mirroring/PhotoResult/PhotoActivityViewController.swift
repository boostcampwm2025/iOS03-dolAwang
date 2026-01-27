//
//  PhotoActivityViewController.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/27/26.
//

import LinkPresentation
import SwiftUI

// MARK: - 공유 시트 담당 ActivityViewController
struct PhotoActivityViewController: UIViewControllerRepresentable {
    let image: UIImage
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let appIcon = getAppIcon()

        // ActivityItemSource 연결
        let itemSource = PhotoActivityItemSource(image: image, appIcon: appIcon)

        let controller = UIActivityViewController(
            activityItems: [itemSource],
            applicationActivities: applicationActivities
        )

        // Activity 제거 (파일에 저장)
        controller.excludedActivityTypes = [
            .saveToCameraRoll,  // 사진에 저장 금지
            .assignToContact,   // 연락처 사진으로 지정 금지
            .addToReadingList,  // 읽기 목록에 추가 금지
            .openInIBooks,      // iBooks 추가 금지
            .addToHomeScreen    // 홈 화면에 추가 금지
        ]

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }

    private func getAppIcon() -> UIImage? {
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last,
           let icon = UIImage(named: lastIcon) {
            return icon
        }

        return UIImage(systemName: "camera.fill")
    }
}

// MARK: - ActivityItemSource (ActivityViewController에 연결되는 프리뷰 인스턴스)
class PhotoActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let appIcon: UIImage?

    init(image: UIImage, appIcon: UIImage?) {
        self.image = image
        self.appIcon = appIcon
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Mirroring Booth"

        // 앱 아이콘 설정
        if let appIcon = appIcon {
            metadata.iconProvider = NSItemProvider(object: appIcon)
        }

        return metadata
    }
}
