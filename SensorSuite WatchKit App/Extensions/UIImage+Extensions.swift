//
//  UIImage+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 8/19/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import UIKit

extension UIImage {
    static func emptyImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
