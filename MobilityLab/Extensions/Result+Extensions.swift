//
//  Result+Extensions.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/8/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Result where Success == Void {
    static var success: Result {
        .success(())
    }
}

extension Result {
    var isSuccess: Bool { if case .success = self { return true } else { return false } }
    var isError: Bool {  return !isSuccess  }
}
