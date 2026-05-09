//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

enum ProvisioningEndpoint {
    case registerBaseStation(deviceId: String)
    case registerMonitor(wearableId: String, guid: String)
    case getCertificateRevocationList(facilityId: String)
    case getAvailableBed(facilityUnitId: String)
    case getConfig(facilityId: String)
    case addPatient(details: StartEndSessionModel)
    case endSession(details: StartEndSessionModel)
    case addPatch(facilityId: String, patientId: String, count: Int, token: String)
    case getUnitRooms(dateAfter: String?)
    case checkUnitRooms(dateAfter: String?)

    var path: String {
        switch self {
        case .registerBaseStation(let deviceId):
            return "api/v1/MobilityLabProvisioning/RegisterBaseStation/\(deviceId)"
        case .registerMonitor(let wearableId, let guid):
            return "api/v1/MobilityLabProvisioning/RegisterMonitor/\(guid)/\(wearableId)"
        case .getCertificateRevocationList(let facilityId):
            return "api/v1/MobilityLabProvisioning/crl/\(facilityId)"
        case .getAvailableBed:
            return "api/v1/MobilityLabProvisioning/BaseStation/GetAvailableRoomBeds"
        case .getConfig(let facilityId):
            return "api/v1/MobilityLabProvisioning/BaseStation/GetMobilityLabConfig/\(facilityId)"
        case .addPatient:
            return "api/v1/MobilityLabProvisioning/BaseStation/AddPatient"
        case .endSession:
            return "api/v1/MobilityLabProvisioning/BaseStation/EndSession"
        case .addPatch:
            return "api/v1/MobilityLabProvisioning/BaseStation/AddPatch"
        case .getUnitRooms:
            return "api/v1/MobilityLabProvisioning/GetUnitRooms"
        case .checkUnitRooms:
            return "api/v1/MobilityLabProvisioning/CheckUnitRooms"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .registerBaseStation, .registerMonitor, .getAvailableBed, .getConfig, .addPatient, .endSession, .addPatch:
            return .post
        case .getCertificateRevocationList, .getUnitRooms, .checkUnitRooms:
            return .get
        }
    }

    var headers: [String: String]? {
        switch self {
        case .registerBaseStation, .registerMonitor:
            return ["Content-Type": "application/octet-stream"]
        case .getCertificateRevocationList:
            return nil
        case .getAvailableBed, .getConfig, .endSession, .addPatient, .getUnitRooms, .checkUnitRooms, .addPatch:
            return ["Content-Type": "application/json"]
        }
    }

    var body: Data? {
        switch self {
        case .registerBaseStation, .registerMonitor:
            return nil
        case .getCertificateRevocationList, .getConfig:
            return nil
        case .getUnitRooms, .checkUnitRooms:
            return nil
        case .getAvailableBed(let facilityUnitId):
            let content = ["FacilityUnitId": facilityUnitId]
            do {
                let data = try JSONSerialization.data(withJSONObject: content)
                return data
            } catch {
                return nil
            }
        case .addPatient(let details):
            return details.toData()
        case .endSession(let details):
            return details.toData()
        case let .addPatch(facilityId, patientId, count, token):
            let content = [
               "NoOfPatches": "\(count)",
               "FacilityId": facilityId,
               "AltPatientId": patientId,
               "token": token,
            ]
            do {
                // it would be nice to JSON Encode this instead so we get control over date format
                return try JSONSerialization.data(withJSONObject: content)
            } catch {
                return nil
            }
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .getUnitRooms(let dateAfter), .checkUnitRooms(let dateAfter):
            guard let dateAfter = dateAfter else {
                return nil
            }
            return ["dateAfter": dateAfter]
        default:
            return nil
        }
    }

    func validate(response: URLResponse) throws(NetworkingError.REST) {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.REST.badResponse
        }
        switch self {
        case .registerBaseStation, .registerMonitor:
            switch response.statusCode {
            case 200...299:
                break
            case 400:
                let message = "The JWT token is no longer valid (expired, references a facility that is turned off, etc.)"
                throw NetworkingError.REST.someError(message)
            case 401:
                let message = "Attempting to register a monitor to a different facility than the JWT token or the token expired"
                throw NetworkingError.REST.someError(message)
            case 500:
                throw NetworkingError.REST.tempServerError
            default:
                throw NetworkingError.REST.badStatusCode(code: response.statusCode)
            }
        case .getCertificateRevocationList, .getAvailableBed, .getConfig, .addPatient, .endSession, .getUnitRooms, .checkUnitRooms, .addPatch:
            guard 200...299 ~= response.statusCode else {
                throw NetworkingError.REST.badStatusCode(code: response.statusCode)
            }
        }
    }
}

extension ProvisioningEndpoint: AuthenticatedEndpointProtocol { }
