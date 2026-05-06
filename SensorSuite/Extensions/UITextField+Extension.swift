//
//  UITextField+Extension.swift
//  SensorSuite
//
//  Created by Josh Franco on 7/27/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import UIKit

extension UITextField {
    @objc
    func doneButtonTapped(button: UIBarButtonItem) {
        self.resignFirstResponder()
    }
}
