//
//  SecurityError.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

enum SecurityError: Error, LocalizedError {
    case unknown
    case jwtNotVerified
    case badKeyData
    case someError(String)
    case noKeychainData
    case noSerialNum
    case noFacilityId
    case revokedByCrl
    case noCerts
    case badTrust
    
    var errorDescription: String? {
        switch self {
        case .jwtNotVerified:
            return "JWT was not Verified"
        case .someError(let string):
            return string
        case .unknown:
            return "Unknown Error"
        case .badKeyData:
            return "Could not turn KeyStr into Data"
        case .noKeychainData:
            return "Could not find data in Keychain"
        case .noSerialNum:
            return "No Certificate Serial Number Found"
        case .noFacilityId:
            return "No Facility Identifier Found"
        case .revokedByCrl:
            return "Revoked By CRL"
        case .noCerts:
            return "None or bad certificate data"
        case .badTrust:
            return "Could not create trust from certificates"
        }
    }
}
