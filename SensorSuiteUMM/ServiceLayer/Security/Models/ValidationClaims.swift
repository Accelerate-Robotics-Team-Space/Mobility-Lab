//
//  ValidationClaim.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftJWT

struct ValidationClaims: Claims {
    let facility: String
    let host: String
    let iss: String?
    let aud: String?
    let ummUrl: String?
    let monitorUrl: String?
    let bsUrl: String?
    let id: String?
}
