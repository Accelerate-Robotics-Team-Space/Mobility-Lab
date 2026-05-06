//
//  SecCertificate+Extensions.swift
//  SensorSuite
//
//  Created by Josh Franco on 10/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension SecCertificate {
    // MARK: - Computed Variables
    var serialNum: String? {
        guard
            let serialNumData = SecCertificateCopySerialNumberData(self, nil),
            let rawData = CFDataGetBytePtr(serialNumData) else { return nil }
        
        let data = Data(bytes: rawData,
                        count: Int(CFDataGetLength(serialNumData)))
        
        if let serialNum = Int(data.hexEncodedString(), radix: 16) {
            return String(serialNum)
        } else {
            return nil
        }
    }
    
    // MARK: - Constructors
    static func constructor(x509Str: String) -> SecCertificate? {
        guard
            let certData = Data(base64Encoded: x509Str),
            let cert = SecCertificateCreateWithData(nil, certData as NSData) else {
            logger.warn("Error Decoding Cert from String")
//            BMMAlertLog(error: )
            return nil
        }
        
        return cert
    }
}
