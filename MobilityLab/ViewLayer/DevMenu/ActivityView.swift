//
//  ActivityView.swift
//  MobilityLab
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//
import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let completion: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let viewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        viewController.completionWithItemsHandler = { _, completed, _, _ in
            if completed { completion?() }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
