//
//  RevokedCertificate.swift
//  MobilityLab
//
//  Created by Josh Franco on 4/27/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

struct RevokedCertificate: DataStorable, Hashable {
    let serialNum: Int
    let revokedOn: String
    let revokedBy: String
    let reason: String
    
    // MARK: - Computed Variables
    var id: Int {
        serialNum
    }
    
    var revokedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        
        return formatter.date(from: revokedOn)
    }
}

// MARK: - Codable
extension RevokedCertificate: Codable {
    enum CodingKeys: String, CodingKey {
        case serialNum = "CertificateSerialNumber"
        case revokedOn = "RevokedOn"
        case revokedBy = "RevokedBy"
        case reason = "Reason"
    }
}
