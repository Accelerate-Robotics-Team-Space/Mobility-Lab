//
//  DeviceRegistration.swift
//  SensorSuite
//
//  Created by Josh Franco on 10/9/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

struct DeviceRegistration: Codable, Hashable {
    let baseStationId: String
    let intermediateCertificate: String
    let certificate: String
    let facilityName: String
    let units: [HospitalUnit]
    let roomBeds: [HospitalRoomBed]
}
