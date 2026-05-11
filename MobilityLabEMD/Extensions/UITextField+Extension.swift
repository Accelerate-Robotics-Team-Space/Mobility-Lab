//
//  UITextField+Extension.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import UIKit

extension UITextField {
    @objc
    func doneButtonTapped(button: UIBarButtonItem) {
        self.resignFirstResponder()
    }
}
