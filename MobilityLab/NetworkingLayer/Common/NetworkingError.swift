//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum NetworkingError {
    enum BLE: Error {
        case unknownErr
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
        case someError(String)
        case badDateFormat
        case notRegistered
    }
}

extension NetworkingError.BLE: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknownErr:
            return "Unknwon Error has occured"
        case .unknownState:
            return "Bluetoothe LE state is unknown"
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
