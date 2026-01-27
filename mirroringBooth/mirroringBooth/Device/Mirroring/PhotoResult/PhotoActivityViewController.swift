//
//  PhotoActivityViewController.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/27/26.
//

import SwiftUI
import LinkPresentation

// MARK: - 공유 시트 담당 ActivityViewController
struct PhotoActivityViewController: UIViewControllerRepresentable {
    let image: UIImage
    let applecationActivities: [UIActivity]?
    let excludedActivityTypes: [UIActivity.ActivityType]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let appIcon = UIImage(named: "AppIcon") ?? UIImage(systemName: "camera.fill")

        // ActivityItemSource 연결
        let itemSource = PhotoActivityItemSource(image: image, appIcon: appIcon)

        let controller = UIActivityViewController(
            activityItems: [itemSource],
            applicationActivities: applecationActivities
        )

        // Activity 제거 (파일에 저장)
        controller.excludedActivityTypes = excludedActivityTypes

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
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

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Mirroring Booth"

        // 앱 아이콘 설정
        if let appIcon = appIcon {
            metadata.iconProvider = NSItemProvider(object: appIcon)
        }

        // 이미지 프리뷰 설정
        metadata.imageProvider = NSItemProvider(object: image)

        return metadata
    }
}
