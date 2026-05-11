//
//  UIApplication+Extensions.swift
//  MobilityLab EMD
//
//  Created by Vadym Riznychok on 6/2/23.
//  Copyright © 2023 Atlas LiftTech. All rights reserved.
//

import UIKit

extension UIApplication {
    func topMostController() -> UIViewController? {
        guard
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first(where: { $0.isKeyWindow }),
            let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
    }

    func dismiss() {
        UIApplication.shared.topMostController()?.dismiss(animated: true, completion: nil)
    }
}
