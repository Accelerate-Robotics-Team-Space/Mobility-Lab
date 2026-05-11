//
//  NetworkingErr.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

enum NetworkingError {
    enum BLE: Error {
        case unknownError
        case unknownState
        case unsupported
        case unauthorized
        case resetting
        case poweredOff
        case noValue
        case notSubscribed
        case noPacketHeader
    }
    
    enum MQTT: Error {
        case noSession
    }
    
    enum REST: Error {
        case badBaseUrl
        case badResponse
        case badStatusCode(code: Int)
        case tempServerError
        case someError(msg: String)
        case badDateFormat
        case notRegistered
    }
}

extension NetworkingError.BLE: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "Unknown Error has occured"
        case .unknownState:
            return "Bluetooth LE state is unknown"
        case .unsupported:
            return "Bluetooth LE is not supported on this device"
        case .unauthorized:
            return "Needs your approval to use Bluetooth LE on this monitor"
        case .resetting:
            return "Bluetooth LE is resetting, please wait..."
        case .poweredOff:
            return "Please turn on Bluetooth from settings and try again"
        case .noValue:
            return "No Value Found"
        case .notSubscribed:
            return "Not Subscribed to Characteristics"
        case .noPacketHeader:
            return "No BLE Packet Header in chunk"
        }
    }
}

extension NetworkingError.MQTT: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No existing MQTT Session"
        }
    }
}

extension NetworkingError.REST: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .badBaseUrl:
            return "Invalid Base URL"
        case .badResponse:
            return "Invalid URL Response"
        case .badStatusCode(let code):
            return "Bad Status Code: \(code)"
        case .tempServerError:
            return "Server error (temporary) - OK to try again later"
        case .someError(let message):
            return message
        case .badDateFormat:
            return "Date format does not match our formatter"
        case .notRegistered:
            return "This device is not registered."
        }
    }
}
