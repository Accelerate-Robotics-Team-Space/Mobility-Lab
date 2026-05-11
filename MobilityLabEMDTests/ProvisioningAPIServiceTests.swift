//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_EMD
import XCTest

final class ProvisioningAPIServiceTests: XCTestCase {
    var urlSession: URLSession!
    var client: AuthenticatedAPIClient<ProvisioningEndpoint>!
    var testSubject: ProvisioningAPIService!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        MockURLProtocol.stopLoadingHandler = { }

        client = AuthenticatedAPIClient(urlSession: urlSession)
        UserDefaults.standard.host = "test.notreal.com"
        testSubject = ProvisioningAPIService(apiClient: client)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        client = nil
        urlSession = nil
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.host.rawValue)
    }

    func testRegisterEMD() async throws {
        let expectation = expectation(description: "provisioningAPI-registerEMD")
        var request: URLRequest?
        MockURLProtocol.requestHandler = { actualRequest in
            request = actualRequest
            expectation.fulfill()
            return (
                HTTPURLResponse(
                    url: URL(string: "https://apple.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                (Data(Self.deviceRegistration.utf8))
            )
        }
        let testID = "Test ID"
        let registration = try await testSubject.registerEMD(deviceId: testID)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(
            request?.url?.absoluteString,
            "\(NetworkingConstants.baseUrlStr)api/v1/MobilityLabProvisioning/RegisterUnitMobilityMonitor/Test%20ID"
        )

        XCTAssertEqual(registration.certificate, "Test Certificate")
        XCTAssertEqual(registration.facilityName, "Test Facility Name")
        XCTAssertEqual(registration.units.count, 1)
        XCTAssertEqual(registration.roomBeds.count, 1)
        XCTAssertEqual(registration.bmMs.count, 1)
    }

    func testGetCRL() async throws {
        let expectation = expectation(description: "provisioningAPI-getCRL")
        var request: URLRequest?
        let response = "This is a Test Code"
        let quote = #"""#

        MockURLProtocol.requestHandler = { actualRequest in
            request = actualRequest
            expectation.fulfill()
            return (
                HTTPURLResponse(
                    url: URL(string: "https://unimportant.for.test.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(
                    (quote + response + quote).utf8
                )
            )
        }
        let facilityId = UUID().uuidString
        let crl = try await testSubject.getCertificateRevocationList(facilityId)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(
            request?.url?.absoluteString,
            "\(NetworkingConstants.baseUrlStr)api/v1/MobilityLabProvisioning/crl/\(facilityId)"
        )
        XCTAssertEqual(crl, response)
    }
}

private extension ProvisioningAPIServiceTests {
    static var deviceRegistration: String {
        """
        {
            "unitMobilityMonitorId": "Monitor ID",
            "intermediateCertificate": "Intermediate Cert",
            "certificate": "Test Certificate",
            "facilityName": "Test Facility Name",
            "units": [
                {
                    "facilityUnitId": "Unit ID",
                    "facilityId": "Unit Facility ID",
                    "departmentId": "Unit Department ID",
                    "name": "Unit Name",
                    "status": "Active",
                    "lastModified": "2022-10-01T03:15:32",
                    "lastModifiedBy": "Unit Modifier",
                    "serverLastModified": "2020-09-05T12:17:12"
                }
            ],
            "roomBeds": [
                {
                    "id": "Room Bed ID",
                    "facilityUnitId": "Room Bed Facility Unit ID",
                    "roomBedNumber": "Room Bed Number",
                    "status": "Active",
                    "lastModified": "2023-09-21T20:35:34",
                    "lastModifiedBy": "Room Bed Modifier",
                    "serverLastModified": "2021-09-21T20:35:34"
                }
            ],
            "bmMs": [
                {
                    "id": "This is an ID",
                    "deviceSerialNumber": "Serial##",
                    "facilityId": "Test Facility ID",
                    "facilityUnitId": "Test Facility Unit ID",
                    "roomBedId": "This is a room Bed ID",
                    "bmmLastSeen": {
                        "facilityUnitId": "Facility Unit ID Last Seen",
                        "facilityUnitName": "Facility Unit Name Last Seen",
                        "roomBedId": "Room Bed Last Seen ID",
                        "roomBedNumber": "Room Bed Last Seen Number",
                        "lastSeenTime": "Last Seen Time",
                        "patientId": "Last Seen Patient ID",
                        "sessionId": "Last Seen Session ID",
                        "turnProtocol": "BMMInfoAPIServiceProtocol",
                        "complianceDegree": 360
                    }
                }
            ]
        }
        """
    }
}
