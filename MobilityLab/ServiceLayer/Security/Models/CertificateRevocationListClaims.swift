//
//  CrlClaims.swift
//  MobilityLab
//
//  Created by Josh Franco on 4/27/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation
import SwiftJWT

struct CertificateRevocationListClaims: Claims {
    let nbf: Date
    let exp: Date
    let iat: Date
    let iss: String
    let aud: String
    let revokedCertificates: [RevokedCertificate]
}
