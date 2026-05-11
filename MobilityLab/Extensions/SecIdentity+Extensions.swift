//
//  SecIdentity+Extensions.swift
//  MobilityLab
//
//  Created by Josh Franco on 5/10/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

extension SecIdentity {
    // MARK: - Computed Variables
    var certificate: SecCertificate? {
        var cert: SecCertificate?
        let status = SecIdentityCopyCertificate(self, &cert)
        if status != errSecSuccess {
            logger.error("SecIdentityCopyCertificate failed")
            return nil
        }
        return cert
    }
    
    // MARK: - Constructors
    // swiftlint:disable empty_count
    // swiftlint:disable force_cast
    static func constructor(p12Str: String) -> SecIdentity? {
        guard let p12Data = NSData(base64Encoded: p12Str,
                                   options: .ignoreUnknownCharacters) else { return nil }
        
        let options = [kSecImportExportPassphrase as String: SecurityConstants.altSecret]
        var p12Items: CFArray?
        let p12ImportResult = withUnsafeMutablePointer(to: &p12Items) {
            SecPKCS12Import(p12Data, options as CFDictionary, $0)
        }
        
        guard p12ImportResult == errSecSuccess else {
            let errMsg = SecCopyErrorMessageString(p12ImportResult, nil) ?? "?" as CFString
            logger.error("P12 Cert Constructor Error: \(errMsg)")
            return nil
        }
        
        guard
            let importedItems = p12Items,
            (importedItems as NSArray).count > 0,
            let identityAndTrust = (importedItems as NSArray).object(at: 0) as? NSDictionary else {
            logger.error("P12 Cert Constructor Error: Bad Data Imported")
            return nil
        }
        
        let identityKey = kSecImportItemIdentity as String
        let identity = identityAndTrust[identityKey] as! SecIdentity
        return identity
    }
}
// swiftlint:enable empty_count
// swiftlint:enable force_cast
