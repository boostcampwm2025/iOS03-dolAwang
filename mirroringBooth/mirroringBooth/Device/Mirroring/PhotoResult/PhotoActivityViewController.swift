//
//  PhotoActivityViewController.swift
//  mirroringBooth
//
//  Created by 윤대현 on 1/27/26.
//

import SwiftUI

struct PhotoActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applecationActivities: [UIActivity]?
    let excludedActivityTypes: [UIActivity.ActivityType]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applecationActivities
        )

        // Activity 제거 (파일에 저장)
        controller.excludedActivityTypes = excludedActivityTypes

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
