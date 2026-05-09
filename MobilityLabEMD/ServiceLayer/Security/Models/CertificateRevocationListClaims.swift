//
//  CrlClaims.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/21/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
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
