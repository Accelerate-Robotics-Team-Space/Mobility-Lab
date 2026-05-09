//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
@testable import MobilityLab_BMM
import XCTest

final class ProvisioningAPIServiceTests: XCTestCase { // swiftlint:disable:this type_body_length
    var container: Container!
    var urlSession: URLSession!
    var userDefaults: MockUserDefaultsService!
    var keychain: MockKeychain!
    var client: AuthenticatedAPIClient<ProvisioningEndpoint>!
    var testSubject: ProvisioningAPIService!

    override func setUp() {
        super.setUp()
        container = .init()
        container.resetAll()

        keychain = MockKeychain()
        keychain.accessToken = "test-token"
        container.keychain.register { self.keychain }

        userDefaults = MockUserDefaultsService()
        userDefaults.host = "test-host"
        container.userDefaults.register { self.userDefaults }

        urlSession = MockURLProtocol.urlSession
        MockURLProtocol.stopLoadingHandler = { }

        client = AuthenticatedAPIClient(urlSession: urlSession, container: container)
        
        testSubject = ProvisioningAPIService(apiClient: client)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        client = nil
        urlSession = nil
        keychain = nil
    }

    func testGetCertificateRevocationList() {
        // GIVEN - a 200 response returning plain text
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("A_Fake_JWT_Token".utf8)
            )
        }

        // WHEN - requesting the certificate revocation list
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: String?
        cancellable = testSubject.getCertificateRevocationList("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { jwtToken in
                    result = jwtToken
                    exp.fulfill()
                }
            )

        // THEN - the expected token is returned
        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "A_Fake_JWT_Token")
    }

    func testRegisterBaseStationPublisher() {
        let json = """
            {
                "baseStationId" : "testBaseStation",
                "certificate" : "fakeCertificate",
                "facilityName" : "testFacility",
                "intermediateCertificate" : "fakeIntCertificate",
                "units" : [
                    {
                        "facilityUnitId" : "unit1",
                        "departmentId" : "mockDept",
                        "lastModifiedBy" : "tester",
                        "facilityId" : "testFacility",
                        "serverLastModified" : "2025-01-01T00:00:00.00",
                        "status" : "great",
                        "lastModified" : "2025-01-01T00:00:00.00",
                        "name" : "unit1"
                    }
                ],
                "roomBeds" : [
                    {
                        "facilityUnitId" : "testFacility",
                        "id" : "roomBed1",
                        "serverLastModified" : "2025-01-01T00:00:00.00",
                        "roomBedNumber" : "room bed 1",
                        "lastModifiedBy" : "tester",
                        "lastModified" : "2025-01-01T00:00:00.00",
                        "status" : "great"
                    }
                ]
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: DeviceRegistration?
        cancellable = testSubject.registerBaseStationPublisher(id: "ID1")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { registration in
                    result = registration
                    exp.fulfill()
                }
            )

        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, .mock())
    }

    func testGetAvailableRoomBed() {
        let json = """
            [
                {
                    "facilityUnitId" : "testFacility",
                    "id" : "roomBed1",
                    "serverLastModified" : "2025-01-01T00:00:00.00",
                    "roomBedNumber" : "room bed 1",
                    "lastModifiedBy" : "tester",
                    "lastModified" : "2025-01-01T00:00:00.00",
                    "status" : "great"
                }
            ]
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: [HospitalRoomBed] = []
        cancellable = testSubject.getAvailableRoomBed("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { array in
                    result = array
                    exp.fulfill()
                }
            )

        wait(for: [exp], timeout: 2)
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result, [.mock()])
    }

    func testAddNewPatient() async {
        let json = """
            {
                "facilityUnitId" : "testFacility"
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        do {
            let result = try await testSubject.addNewPatient(.mock())

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.keys.first, "facilityUnitId")
            XCTAssertEqual(result.values.first as? String, "testFacility")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testEndPatientSession() async {
        let json = """
            {
                "facilityUnitId" : "testFacility"
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        do {
            let result = try await testSubject.endPatientSession(.mock())

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.keys.first, "facilityUnitId")
            XCTAssertEqual(result.values.first as? String, "testFacility")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testGetConfig() {
        let json = """
            {
                "turnProtocol" : "testProtocol",
                "complianceDegree" : 200
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: FacilityConfig?
        cancellable = testSubject.getConfig("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { config in
                    result = config
                    exp.fulfill()
                }
            )

        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, .mock())
    }

    func testAddOnePatch() async {
        // GIVEN - a 200 response for addPatch
        let json = """
            {
                "facilityUnitId" : "testFacility"
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        // WHEN - invoking addOnePatch
        do {
            let result = try await testSubject.addOnePatch(
                "facilityID",
                patientId: "patientID",
                patchCount: 20,
                token: "a token"
            )

            // THEN - a non-empty response is returned
            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.keys.first, "facilityUnitId")
            XCTAssertEqual(result.values.first as? String, "testFacility")
        } catch {
            XCTFail("Failed: \(error)")
        }
    }

    func testGetUnitRooms() {
        let json = """
            {
                "units" : [
                    {
                        "lastModifiedBy" : "tester",
                        "departmentId" : "mockDept",
                        "facilityUnitId" : "unit1",
                        "facilityId" : "testFacility",
                        "name" : "unit1",
                        "status" : "great",
                        "lastModified" : "2025-01-01T00:00:00.00",
                        "serverLastModified" : "2025-01-01T00:00:00.00"
                    }
                ],
                "roomBeds" : [
                    {
                        "id" : "roomBed1",
                        "facilityUnitId" : "testFacility",
                        "status" : "great",
                        "roomBedNumber" : "room bed 1",
                        "lastModified" : "2025-01-01T00:00:00.00",
                        "lastModifiedBy" : "tester",
                        "serverLastModified" : "2025-01-01T00:00:00.00"
                    }
                ],
                "facilityId" : "C557C3F9-433A-4A4D-8480-310A42886407",
                "facilityName" : "Bob Jennings"
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: UnitRoomModel?
        cancellable = testSubject.getUnitRooms()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { unitRooms in
                    result = unitRooms
                    exp.fulfill()
                }
            )

        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, .mock())
    }

    func testCheckIfUnitRoomsAdded() {
        let json = """
            {
                "status" : true,
                "data" : false
            }
            """

        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data(json.utf8)
            )
        }

        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var result: CheckUnitModel?
        cancellable = testSubject.checkIfUnitRoomsAdded()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                        cancellable?.cancel()
                    }
                },
                receiveValue: { unitRooms in
                    result = unitRooms
                    exp.fulfill()
                }
            )

        wait(for: [exp], timeout: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, .mock())
    }

    func testGetCertificateRevocationList_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - requesting the certificate revocation list
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.getCertificateRevocationList("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    func testRegisterBaseStationPublisher_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - registering base station
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.registerBaseStationPublisher(id: "ID1")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { (_: DeviceRegistration) in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    func testGetAvailableRoomBed_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - requesting available room beds
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.getAvailableRoomBed("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { (_: [HospitalRoomBed]) in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    func testGetConfig_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - requesting facility config
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.getConfig("facilityID")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { (_: FacilityConfig) in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    func testAddNewPatient_Failure() async {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN/THEN - invoking addNewPatient should throw
        do {
            _ = try await testSubject.addNewPatient(.mock())
            XCTFail("Expected addNewPatient to throw on failure status code")
        } catch {
            // THEN - error is thrown as expected
            XCTAssertTrue(true)
        }
    }

    func testEndPatientSession_Failure() async {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN/THEN - invoking endPatientSession should throw
        do {
            _ = try await testSubject.endPatientSession(.mock())
            XCTFail("Expected endPatientSession to throw on failure status code")
        } catch {
            // THEN - error is thrown as expected
            XCTAssertTrue(true)
        }
    }

    func testAddOnePatch_Failure() async {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN/THEN - invoking addOnePatch should throw
        do {
            _ = try await testSubject.addOnePatch(
                "facilityID",
                patientId: "patientID",
                patchCount: 20,
                token: "a token"
            )
            XCTFail("Expected addOnePatch to throw on failure status code")
        } catch {
            // THEN - error is thrown as expected
            XCTAssertTrue(true)
        }
    }

    func testGetUnitRooms_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - requesting unit rooms
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.getUnitRooms()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { (_: UnitRoomModel) in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    func testCheckIfUnitRoomsAdded_Failure() {
        // GIVEN - a 500 response
        MockURLProtocol.requestHandler = { _ in
            (
                HTTPURLResponse(
                    url: URL(string: "https://atlasmobility.com/Path")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("error".utf8)
            )
        }

        // WHEN - checking if unit rooms were added
        var cancellable: AnyCancellable?
        let exp = XCTestExpectation(description: #function)
        var didFail = false
        cancellable = testSubject.checkIfUnitRoomsAdded()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        cancellable?.cancel()
                    case .failure:
                        didFail = true
                        exp.fulfill()
                        cancellable?.cancel()
                    }
                },
                receiveValue: { (_: CheckUnitModel) in
                    XCTFail("Should not receive a value on failure")
                }
            )

        // THEN - the publisher fails
        wait(for: [exp], timeout: 2)
        XCTAssertTrue(didFail)
    }

    // MARK: - ProvisioningEndpoint.validate(response:) direct tests
    func testValidate_RegisterBaseStation_2xx_OK() {
        // GIVEN - a 2xx response
        let endpoint = ProvisioningEndpoint.registerBaseStation(deviceId: "dev1")
        let response = httpResponse(204)

        // WHEN/THEN - validate should not throw
        XCTAssertNoThrow(try endpoint.validate(response: response))
    }

    func testValidate_RegisterBaseStation_400_JWTInvalid() {
        // GIVEN - a 400 response
        let endpoint = ProvisioningEndpoint.registerBaseStation(deviceId: "dev1")
        let response = httpResponse(400)

        // WHEN/THEN - validate should throw the specific JWT invalid error
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 400")
        } catch {
            if case .someError(let message) = error {
                XCTAssertEqual(message, "The JWT token is no longer valid (expired, references a facility that is turned off, etc.)")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterBaseStation_401_AttemptDifferentFacility() {
        // GIVEN - a 401 response
        let endpoint = ProvisioningEndpoint.registerBaseStation(deviceId: "dev1")
        let response = httpResponse(401)

        // WHEN/THEN - validate should throw the specific 401 error
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 401")
        } catch {
            if case .someError(let message) = error {
                XCTAssertEqual(message, "Attempting to register a monitor to a different facility than the JWT token or the token expired")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterBaseStation_500_TempServerError() {
        // GIVEN - a 500 response
        let endpoint = ProvisioningEndpoint.registerBaseStation(deviceId: "dev1")
        let response = httpResponse(500)

        // WHEN/THEN - validate should throw tempServerError
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 500")
        } catch {
            if case .tempServerError = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterBaseStation_Default_BadStatus() {
        // GIVEN - a non-mapped status code
        let endpoint = ProvisioningEndpoint.registerBaseStation(deviceId: "dev1")
        let response = httpResponse(418)

        // WHEN/THEN - validate should throw badStatusCode(418)
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 418")
        } catch {
            if case .badStatusCode(let code) = error {
                XCTAssertEqual(code, 418)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterMonitor_2xx_OK() {
        // GIVEN - a 2xx response
        let endpoint = ProvisioningEndpoint.registerMonitor(wearableId: "w1", guid: "g1")
        let response = httpResponse(201)

        // WHEN/THEN - validate should not throw
        XCTAssertNoThrow(try endpoint.validate(response: response))
    }

    func testValidate_RegisterMonitor_400_JWTInvalid() {
        // GIVEN - a 400 response
        let endpoint = ProvisioningEndpoint.registerMonitor(wearableId: "w1", guid: "g1")
        let response = httpResponse(400)

        // WHEN/THEN - validate should throw the specific JWT invalid error
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 400")
        } catch {
            if case .someError(let message) = error {
                XCTAssertEqual(message, "The JWT token is no longer valid (expired, references a facility that is turned off, etc.)")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterMonitor_401_AttemptDifferentFacility() {
        // GIVEN - a 401 response
        let endpoint = ProvisioningEndpoint.registerMonitor(wearableId: "w1", guid: "g1")
        let response = httpResponse(401)

        // WHEN/THEN - validate should throw the specific 401 error
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 401")
        } catch {
            if case .someError(let message) = error {
                XCTAssertEqual(message, "Attempting to register a monitor to a different facility than the JWT token or the token expired")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterMonitor_500_TempServerError() {
        // GIVEN - a 500 response
        let endpoint = ProvisioningEndpoint.registerMonitor(wearableId: "w1", guid: "g1")
        let response = httpResponse(500)

        // WHEN/THEN - validate should throw tempServerError
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 500")
        } catch {
            if case .tempServerError = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_RegisterMonitor_Default_BadStatus() {
        // GIVEN - a non-mapped status code
        let endpoint = ProvisioningEndpoint.registerMonitor(wearableId: "w1", guid: "g1")
        let response = httpResponse(422)

        // WHEN/THEN - validate should throw badStatusCode(422)
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 422")
        } catch {
            if case .badStatusCode(let code) = error {
                XCTAssertEqual(code, 422)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_GenericEndpoint_500_BadStatus() {
        // GIVEN - a generic endpoint and 500 response
        let endpoint = ProvisioningEndpoint.getConfig(facilityId: "f1")
        let response = httpResponse(500)

        // WHEN/THEN - validate should throw badStatusCode(500)
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw for 500")
        } catch {
            if case .badStatusCode(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testValidate_NonHTTPResponse_BadResponse() {
        // GIVEN - a non-HTTP URLResponse
        let endpoint = ProvisioningEndpoint.getConfig(facilityId: "f1")
        let response = URLResponse(
            url: URL(string: "https://atlasmobility.com/Path")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        // WHEN/THEN - validate should throw badResponse
        do {
            try endpoint.validate(response: response)
            XCTFail("Expected to throw badResponse for non-HTTP response")
        } catch {
            if case .badResponse = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

// MARK: - Test Fixtures

private extension ProvisioningAPIServiceTests {
    func httpResponse(_ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://atlasmobility.com/Path")!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

private extension DeviceRegistration {
    static func mock() -> DeviceRegistration {
        DeviceRegistration(
            baseStationId: "testBaseStation",
            intermediateCertificate: "fakeIntCertificate",
            certificate: "fakeCertificate",
            facilityName: "testFacility",
            units: [.mock()],
            roomBeds: [.mock()]
        )
    }
}

private extension HospitalUnit {
    static func mock(
        id: String = "unit1"
    ) -> HospitalUnit {
        HospitalUnit(
            id: id,
            facilityId: "testFacility",
            departmentId: "mockDept",
            name: "unit1",
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "tester",
            serverLastModified: .twenty25
        )
    }
}

private extension HospitalRoomBed {
    static func mock(
        id: String = "roomBed1"
    ) -> HospitalRoomBed {
        HospitalRoomBed(
            id: id,
            facilityUnitId: "testFacility",
            roomBedNumber: "room bed 1",
            status: "great",
            lastModified: .twenty25,
            lastModifiedBy: "tester",
            serverLastModified: .twenty25
        )
    }
}

private extension StartEndSessionModel {
    static func mock() -> StartEndSessionModel {
        StartEndSessionModel(
            baseStationId: "baseStation1",
            facilityId: "testFacility",
            patientDetails: .mock()
        )
    }
}

private extension PublishablePatient {
    static func mock() -> PublishablePatient {
        PublishablePatient(
            patientId: "testPatient",
            sex: .female,
            weight: 100,
            height: 100,
            bmi: 100,
            hasPaceMaker: false,
            hasSternumSkinBroken: false,
            roomBedId: "TestRoom1",
            facilityUnitId: "unit1",
            turnProtocol: "testTurnProtocol",
            complianceDegree: 50
        )
    }
}

private extension FacilityConfig {
    static func mock() -> FacilityConfig {
        FacilityConfig(
            complianceDegree: 200,
            turnProtocol: "testProtocol",
            enableCompliance: nil,
            enableTurnProtocol: nil
        )
    }
}

private extension UnitRoomModel {
    static func mock() -> UnitRoomModel {
        UnitRoomModel(
            facilityName: "Bob Jennings",
            facilityId: UUID(uuidString: "c557c3f9-433a-4a4d-8480-310a42886407")!,
            units: [.mock()],
            roomBeds: [.mock()]
        )
    }
}

private extension CheckUnitModel {
    static func mock() -> CheckUnitModel {
        CheckUnitModel(
            doesNotHaveNewUnitsOrRooms: false,
            httpSuccess: true,
            exceptionCode: nil
        )
    }
} // swiftlint:disable:this file_length
