//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import SensorSuite_UMM
import XCTest

final class BMMInfoAPIServiceTests: XCTestCase {
    var urlSession: URLSession!
    var client: AuthenticatedAPIClient<BMMInfoEndpoint>!
    var testSubject: BMMInfoAPIService!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        MockURLProtocol.stopLoadingHandler = { }

        client = AuthenticatedAPIClient(urlSession: urlSession)

        testSubject = BMMInfoAPIService(apiClient: client)
    }

    override func tearDown() {
        super.tearDown()
        testSubject = nil
        client = nil
        urlSession = nil
    }

    func testFetchBMMList() async throws {
        let expectation = expectation(description: "bmmInfoAPI-fetchBMMList")
        var request: URLRequest?
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
                    ("[" + Self.bmmJson + "]").utf8
                )
            )
        }
        let testID = "Test ID"
        let bmmList = try await testSubject.fetchBMMList(for: testID)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(
            request?.url?.absoluteString,
            "\(NetworkingConstants.baseUrlStr)api/v1/SensorSuiteProvisioning/GetUnitMobilityMonitor/Test%20ID"
        )
        XCTAssertEqual(bmmList, [BMMStruct.bmm1])
    }

    func testFetchBMMStatuses() async throws {
        let expectation = expectation(description: "bmmInfoAPI-fetchBMMStatuses")
        var request: URLRequest?
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
                    ("[" + Self.statusJson + "]").utf8
                )
            )
        }
        let testID = "Test ID"
        let bmmStatusList: [BMMStatus] = try await testSubject.fetchBMMStatuses(for: testID)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(
            request?.url?.absoluteString,
            "\(NetworkingConstants.baseUrlStr)api/v1/SensorSuiteProvisioning/GetUMMReconnect/Test%20ID"
        )
        XCTAssertEqual(bmmStatusList, [BMMStatus.status1])
    }

    func testFetchAnalytics() async throws {
        let expectation = expectation(description: "bmmInfoAPI-fetchAnalytics")
        var request: URLRequest?
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
                    (Self.analyticsJson).utf8
                )
            )
        }

        let analyticsRequest = AnalyticsRequestData(
            bmmId: "bmm1",
            facilityId: "facility1",
            ummId: "umm1",
            sessionId: "session1",
            date: "date1"
        )
        let analyticsResponse = try await testSubject.fetchAnalytics(with: analyticsRequest)

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(
            request?.url?.absoluteString,
            "\(NetworkingConstants.baseUrlStr)api/v1/SensorSuiteProvisioning/GetUMMAnalytics/LastDayFromTheDate"
        )
        XCTAssertEqual(analyticsResponse, .response1)
    }
}

// MARK: - Test Fixtures
private extension BMMInfoAPIServiceTests {
    static var bmmJson = """
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
         """

    static var statusJson = """
        {
            "startBMMState": "Test State",
            "bmmMonitoringState": "BMM Monitor State",
            "bmmPauseReason": "Just Because",
            "isWrongPosition": true,
            "actualPosition": "Actual Position",
            "actualPositionStarted": "Yes",
            "startingTargetPosition": "Test Position",
            "startingTimeRemaining": 7894,
            "sessionStartTime": "Lorum Ipsum",
            "roomBed": "Test Room",
            "facilityUnitName": "Harrold",
            "patientInfo": \(patientInfoJson),
            "bmmName": "John",
            "bmmId": "Reginald",
            "status": "Off the chart",
            "turnAngle": 20,
            "headOfBedAngle": 20,
            "bmmBatteryLevel": 50,
            "sensorBatteryLevel": 50
        }
        """

    static var patientInfoJson = """
        {
            "id": 123456,
            "sexAtMeasurement": "Hello",
            "weightInPounds": 45,
            "heightInInches": 90,
            "hasPacemaker": true,
            "hasSternumSkinBroken": false,
            "props": "ABCDEFG",
            "turnProtocol": "BMMInfoAPIServiceProtocol",
            "complianceDegree": 360
        }
        """

    static var analyticsJson = """
        {
            "bmmPositions" : {
                "test1" : [
                    \(logItemJson)
                ]
            },
            "turnsList": {
                "Tuesday" : [
                    "1998-04-08T15:46:23",
                    "2024-09-16T15:46:23"
                ]
            },
            "turnsListDetail": {
                "abb5e170-3a71-ef11-bdfd-0022487eacbb": [
                    {
                        "turnTime": "1998-04-08T15:46:23",
                        "targetPosition": "Supine"
                    }
                ]
            }
        }
        """

    static var logItemJson = """
        {
            "bmmMonitoringState": "Going",
            "bmmPauseReason": "No Reason",
            "isWrongPosition": true,
            "actualPosition": "Flying",
            "actualPositionStarted": "1998-04-08T15:46:23",
            "actualPositionEnded": "2024-09-16T15:46:23",
            "startingTargetPosition": "Supine",
            "startingTimeRemaining": 123456789,
            "bmmName": "Gerald",
            "bmmId": "Gerald's ID",
            "sessionId": "Session ID1",
            "patientId": "Patient ID1"
        }
        """
}

private extension BMMStruct {
    static var bmm1: BMMStruct {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .defaultDecoding
        let data = Data(BMMInfoAPIServiceTests.bmmJson.utf8)
        do {
            return try decoder.decode(BMMStruct.self, from: data)
        } catch {
            fatalError("error decoding \(error)")
        }
    }
}

private extension BMMStatus {
    static var status1: BMMStatus {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .defaultDecoding
        let data = Data(BMMInfoAPIServiceTests.statusJson.utf8)
        do {
            return try decoder.decode(BMMStatus.self, from: data)
        } catch {
            fatalError("error decoding \(error)")
        }
    }
}

private extension AnalyticsResponse {
    static var response1: Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .defaultDecoding
        let data = Data(BMMInfoAPIServiceTests.analyticsJson.utf8)
        do {
            return try decoder.decode(Self.self, from: data)
        } catch {
            print(error)
            fatalError("error decoding \(error)")
        }
    }
}

private extension AnalyticsLogItem {
    static var item1: Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .defaultDecoding
        let data = Data(BMMInfoAPIServiceTests.logItemJson.utf8)
        do {
            return try decoder.decode(Self.self, from: data)
        } catch {
            fatalError("error decoding \(error)")
        }
    }
}
