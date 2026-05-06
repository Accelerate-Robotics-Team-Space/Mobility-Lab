//
//  ValidationClaim.swift
//  SensorSuite
//
//  Created by Josh Franco on 4/27/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
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
