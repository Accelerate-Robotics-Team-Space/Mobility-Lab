//
//  SecCertificate+Extensions.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

extension SecCertificate {
    // MARK: - Computed Variables
    var serialNum: String? {
        guard let serialNumber else {
            return nil
        }
        return String(serialNumber)
    }

    var serialNumber: Int? {
        guard let serialNumData = SecCertificateCopySerialNumberData(self, nil),
              let rawData = CFDataGetBytePtr(serialNumData) else {
            return nil
        }
        let data = Data(bytes: rawData, count: Int(CFDataGetLength(serialNumData)))
        return Int(data.hexEncodedString(), radix: 16)
    }

    // MARK: - Constructors
    static func constructor(x509Str: String) -> SecCertificate? {
        guard let certData = Data(base64Encoded: x509Str),
              let cert = SecCertificateCreateWithData(nil, certData as NSData) else {
            logger.warn("Error Decoding Cert from String")
            return nil
        }
        
        return cert
    }
}
