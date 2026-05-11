//
//  Double+Extensions.swift
//  MobilityLab
//
//  Created by Nguyen Bui on 12/29/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
