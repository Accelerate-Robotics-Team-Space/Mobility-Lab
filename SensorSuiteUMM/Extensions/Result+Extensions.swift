//
//  Result+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension Result where Success == Void {
    static var success: Result {
        .success(())
    }
}
