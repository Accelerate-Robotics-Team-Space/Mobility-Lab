//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation
@testable import SensorSuite_UMM
import XCTest

final class SecurityServiceTests: XCTestCase {

    var provisioningAPIService: MockProvisioningAPIService!
    var keychain: MockKeychainService!
    var userDefaults: MockUserDefaultsService!
    var notificationService: MockNotificationService!
    var testSubject: SecurityService!

    override func setUp() {
        super.setUp()
        Container.shared.resetAll()

        provisioningAPIService = MockProvisioningAPIService()
        Container.shared.provisioningAPIService.register { self.provisioningAPIService }

        keychain = MockKeychainService()
        Container.shared.keychain.register { self.keychain }

        userDefaults = MockUserDefaultsService()
        Container.shared.userDefaults.register { self.userDefaults }

        notificationService = MockNotificationService()
        Container.shared.notification.register { self.notificationService }

        // set handlers called on SecurityService .init
        keychain.resetHandler = { }
        userDefaults.resetHandler = { }
        notificationService.postHandler = { _ in }

        testSubject = SecurityService()
    }

    override func tearDown() {
        super.tearDown()
        provisioningAPIService = nil
        keychain = nil
        userDefaults = nil
        testSubject = nil
    }

    func testValidateToken() {
        let token = Self.jwtToken
        var resultString: String?

        let expectationValidate = expectation(description: "SecurityService-Validate")
        testSubject.validateToken(token, result: { result in
            switch result {
            case let .success((success, _)):
                resultString = success
            case .failure:
                XCTFail("JWT Was Not Decoded")
            }
            expectationValidate.fulfill()
        })

        wait(for: [expectationValidate], timeout: 1)

        XCTAssertEqual(resultString, "7b2dc232-2827-48e5-a69f-d50aa442f1bd")
    }

    func testRegisterDevice() {
        let facilityID = "Current Facility"
        let registration: DeviceRegistration = .registration1
        // let cert = SecCertificate.cert0
        var key: SecKey?
        let expection = expectation(description: "SecurityService-register")
        testSubject.registerDevice(registration, currentFacilityId: facilityID, result: { result in
            switch result {
            case .success(let secKey):
                key = secKey
            case .failure(let failure):
                XCTFail("Failed to Register: \(failure)")
            }
            expection.fulfill()
        })

        wait(for: [expection], timeout: 1)

        XCTAssertNotNil(key)
        XCTAssertNotNil(keychain.deviceCertIdentity)
        XCTAssertNotNil(keychain.devicePublicKey)
        XCTAssertNotNil(keychain.deviceIntermediateCert)
        XCTAssertNotNil(userDefaults.unitMobilityMonitorGuid)
        XCTAssertNotNil(userDefaults.facilityId)
        XCTAssertNotNil(userDefaults.facilityName)
    }

    func testResetDeviceRegistered() {
        var userDefaultsWereReset = false
        var keychainWasReset = false
        var revokeNotificationPosted = false

        let expectationUserDefaults = expectation(description: "securityService-resetDevice-userDefaults")
        let expectationKeychain = expectation(description: "securityService-resetDevice-keychain")
        let expectationNotification = expectation(description: "securityService-resetDevice-notification")

        userDefaults.resetHandler = {
            userDefaultsWereReset = true
            expectationUserDefaults.fulfill()
        }

        keychain.resetHandler = {
            keychainWasReset = true
            expectationKeychain.fulfill()
        }

        notificationService.postHandler = { key in
            if key == .revokedNote {
                revokeNotificationPosted = true
            }
            expectationNotification.fulfill()
        }

        testSubject.resetDeviceRegistered()

        let expectations: [XCTestExpectation] = [
            expectationUserDefaults,
            expectationKeychain,
            expectationNotification,
        ]

        wait(for: expectations, timeout: 1)

        XCTAssertTrue(userDefaultsWereReset)
        XCTAssertTrue(keychainWasReset)
        XCTAssertTrue(revokeNotificationPosted)
        // TODO - refactor DB access through a service so it can be tested
        // Test if `HospitalRoomBed`s have been deleted
        // Test if `HospitalUnit`s have been deleted
    }
}

// swiftlint:disable line_length
private extension SecurityServiceTests {
    static var jwtToken: String {
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6InNjb3R0c3ltZXMiLCJmYWNpbGl0eSI6IjdiMmRjMjMyLTI4MjctNDhlNS1hNjlmLWQ1MGFhNDQyZjFiZCIsImJzVXJsIjoiL2FwaS92MS9TZW5zb3JTdWl0ZVByb3Zpc2lvbmluZy9SZWdpc3RlckJhc2VTdGF0aW9uL18iLCJtb25pdG9yVXJsIjoiL2FwaS92MS9TZW5zb3JTdWl0ZVByb3Zpc2lvbmluZy9SZWdpc3Rlck1vbml0b3IvMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwL18iLCJ1bW1VcmwiOiIvYXBpL3YxL1NlbnNvclN1aXRlUHJvdmlzaW9uaW5nL1JlZ2lzdGVyVW5pdE1vYmlsaXR5TW9uaXRvci9fIiwiaG9zdCI6InNzZGV2aWNlYXBpYWJyYXpvZGV2LmF6dXJld2Vic2l0ZXMubmV0IiwibmJmIjoxNzUwMDkyNTM1LCJleHAiOjE3ODE2Mjg1MzUsImlhdCI6MTc1MDA5MjUzNSwiaXNzIjoiaHR0cHM6Ly9sb2NhbGhvc3Q6NTI0MjUiLCJhdWQiOiJodHRwczovL2xvY2FsaG9zdDo1MjQyNSJ9.BhSCFybDnj5dbrmjeY6_d1tcwm1cVZ9Cm0ZLA7AyME0"
    }
}

private extension SecCertificate {
    static var cert0: SecCertificate {
        let crtBase64 = "MIIGNjCCBB6gAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwga8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlTYW4gUmFtb24xHTAbBgNVBAoMFEF0bGFzIExpZnQgVGVjaCBJbmMuMTIwMAYDVQQLDClBdGxhcyBMaWZ0IFRlY2ggSW5jIENlcnRpZmljYXRlIEF1dGhvcml0eTEkMCIGA1UEAwwbQXRsYXMgTGlmdCBUZWNoIEluYyBSb290IENBMB4XDTIwMDkwMzAwMDIwMloXDTMwMDkwMTAwMDIwMlowgaMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMR0wGwYDVQQKDBRBdGxhcyBMaWZ0IFRlY2ggSW5jLjEyMDAGA1UECwwpQXRsYXMgTGlmdCBUZWNoIEluYyBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkxLDAqBgNVBAMMI0F0bGFzIExpZnQgVGVjaCBJbmMgSW50ZXJtZWRpYXRlIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAs2I85TzTL4vVVvttTuRXrGaVN/MBDf7u+k0IfgFloogs2RS9VM/mxumZiNer6z4UYs3jg9CddoW8V9lwPaNhpyqzdb3eoeW5DQ7BjFB8ZsMcELeqQQbivCZpDc/fzCdf7HMWQdtvsEzdyanZ+gHvQu5Ea+ylgPZkhlm7klPOWNYcLrr0wP4lT6W8eU0phZ2QvDDLvAyfvT8eOw0j6GbZ7Gl0SE8NViSJIRjSKkrkt+KH8mruzMeeZazwYThNJ+OTIThaLNvt/sQW81flhfybr2XQVEso2MednoJtz46I0XusfkCgcaJVyXLXpQio4tS+t+8shhqVUXvkGjP9sgDRfKBs1FxQO88U8+tLi7NbnMNNkshe+5wiqMkO+yWCwogN8/bNrXoW+GJsD1ExYrLS0ql+gVx9WB7jyauLNaODveFQFjzSzmzb"
        guard let certificateData = Data(base64Encoded: crtBase64, options: .ignoreUnknownCharacters) else {
            fatalError("Could not convert Data")
        }
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            fatalError("Could not create certificate")
        }
        return certificate
    }

    static var cert1: SecCertificate? {
        SecCertificate.constructor(x509Str: "MIIGNjCCBB6gAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwga8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlTYW4gUmFtb24xHTAbBgNVBAoMFEF0bGFzIExpZnQgVGVjaCBJbmMuMTIwMAYDVQQLDClBdGxhcyBMaWZ0IFRlY2ggSW5jIENlcnRpZmljYXRlIEF1dGhvcml0eTEkMCIGA1UEAwwbQXRsYXMgTGlmdCBUZWNoIEluYyBSb290IENBMB4XDTIwMDkwMzAwMDIwMloXDTMwMDkwMTAwMDIwMlowgaMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMR0wGwYDVQQKDBRBdGxhcyBMaWZ0IFRlY2ggSW5jLjEyMDAGA1UECwwpQXRsYXMgTGlmdCBUZWNoIEluYyBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkxLDAqBgNVBAMMI0F0bGFzIExpZnQgVGVjaCBJbmMgSW50ZXJtZWRpYXRlIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAs2I85TzTL4vVVvttTuRXrGaVN/MBDf7u+k0IfgFloogs2RS9VM/mxumZiNer6z4UYs3jg9CddoW8V9lwPaNhpyqzdb3eoeW5DQ7BjFB8ZsMcELeqQQbivCZpDc/fzCdf7HMWQdtvsEzdyanZ+gHvQu5Ea+ylgPZkhlm7klPOWNYcLrr0wP4lT6W8eU0phZ2QvDDLvAyfvT8eOw0j6GbZ7Gl0SE8NViSJIRjSKkrkt+KH8mruzMeeZazwYThNJ+OTIThaLNvt/sQW81flhfybr2XQVEso2MednoJtz46I0XusfkCgcaJVyXLXpQio4tS+t+8shhqVUXvkGjP9sgDRfKBs1FxQO88U8+tLi7NbnMNNkshe+5wiqMkO+yWCwogN8/bNrXoW+GJsD1ExYrLS0ql+gVx9WB7jyauLNaODveFQFjzSzmzb")
    }
}

private extension SecIdentity {
    static var certIdent: SecIdentity? {
        SecIdentity.constructor(p12Str: "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")
    }
}

private extension DeviceRegistration {
    static var registration1: Self {
        DeviceRegistration(
            unitMobilityMonitorId: "551e00e8-c364-ef11-bdfd-002248b95c5f",
            intermediateCertificate: "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",
            certificate: "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",
            facilityName: "Atlas Medical Center",
            units: [],
            roomBeds: [],
            bmMs: []
        )
    }
}

// swiftlint:enable line_length

private extension SecKey {
    static var privateKey1: SecKey {
        Self.createKey(modulus: Self.modulus, exponent: Self.exponent, type: kSecAttrKeyClassPrivate)
    }

    static var publicKey1: SecKey {
        Self.createKey(modulus: Self.modulus2, exponent: Self.exponent, type: kSecAttrKeyClassPublic)
    }

    static func createKey(modulus: [UInt8], exponent: [UInt8], type: CFString) -> SecKey {
        var modulus = modulus
        let exponent = exponent

        modulus.insert(0x00, at: 0)

        var modulusEncoded: [UInt8] = []
        modulusEncoded.append(0x02)
        modulusEncoded.append(contentsOf: modulus.lengthField)
        modulusEncoded.append(contentsOf: modulus)

        var exponentEncoded: [UInt8] = []
        exponentEncoded.append(0x02)
        exponentEncoded.append(contentsOf: exponent.lengthField)
        exponentEncoded.append(contentsOf: exponent)

        var sequenceEncoded: [UInt8] = []
        sequenceEncoded.append(0x30)
        sequenceEncoded.append(contentsOf: (modulusEncoded + exponentEncoded).lengthField)
        sequenceEncoded.append(contentsOf: (modulusEncoded + exponentEncoded))

        let keyData = Data(sequenceEncoded)

        // RSA key size is the number of bits of the modulus.
        let keySize = (modulus.count * 8)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: type,
            kSecAttrKeySizeInBits as String: keySize,
        ]

        guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil) else {
            fatalError("Could Not Create Key")
        }
        return key
    }

    static var exponent: [UInt8] {
        [1, 0, 1]
    }

    static var modulus: [UInt8] {
        [
            136, 0, 243, 196, 194, 126, 151, 243, 72, 84, 246, 234, 207, 215,
            168, 5, 233, 212, 8, 37, 34, 52, 215, 217, 223, 183, 58, 129, 66,
            112, 88, 71, 201, 71, 33, 156, 132, 7, 189, 234, 110, 6, 46, 189,
            233, 206, 61, 128, 220, 138, 56, 49, 34, 159, 245, 208, 214, 49,
            169, 58, 170, 68, 127, 93, 137, 99, 74, 54, 65, 109, 112, 33, 65,
            169, 246, 176, 128, 121, 171, 35, 214, 236, 210, 123, 94, 146, 86,
            30, 134, 135, 116, 124, 4, 55, 208, 163, 219, 220, 203, 249, 107,
            69, 147, 169, 66, 214, 179, 195, 152, 211, 209, 78, 100, 114, 209,
            203, 120, 16, 254, 24, 39, 143, 79, 49, 202, 10, 37, 2, 155, 162,
            14, 253, 194, 205, 74, 116, 60, 205, 25, 53, 85, 144, 72, 11, 7,
            133, 78, 149, 111, 0, 215, 174, 36, 104, 175, 62, 196, 197, 49,
            78, 172, 146, 82, 216, 160, 45, 48, 212, 50, 168, 208, 255, 205,
            82, 22, 11, 13, 156, 197, 42, 159, 26, 124, 237, 178, 131, 239,
            186, 37, 96, 24, 154, 243, 202, 252, 87, 102, 23, 19, 29, 73,
            130, 95, 45, 219, 104, 13, 54, 30, 165, 144, 223, 1, 14, 169,
            100, 111, 246, 54, 185, 47, 156, 238, 249, 88, 33, 244, 135,
            233, 102, 36, 86, 196, 143, 178, 176, 62, 24, 178, 209, 163,
            244, 116, 236, 81, 177, 190, 205, 140, 230, 6, 113, 158, 105,
            111, 123,
        ]
    }

    static var modulus2: [UInt8] {
        [
            136, 0, 243, 196, 194, 126, 151, 243, 72, 84, 246, 234, 207, 215,
            168, 5, 233, 212, 8, 37, 34, 52, 215, 217, 223, 183, 58, 129, 66,
            112, 88, 71, 201, 71, 33, 156, 132, 7, 189, 234, 110, 6, 46, 189,
            233, 206, 61, 138, 220, 138, 56, 49, 34, 159, 245, 208, 214, 49,
            169, 58, 170, 68, 127, 93, 137, 99, 74, 54, 65, 109, 112, 33, 65,
            169, 246, 176, 128, 121, 171, 35, 214, 236, 210, 123, 94, 146, 86,
            30, 134, 135, 156, 124, 4, 55, 208, 163, 219, 220, 203, 249, 107,
            69, 147, 169, 66, 202, 179, 195, 152, 211, 209, 78, 100, 114, 209,
            203, 120, 16, 224, 24, 39, 143, 79, 49, 202, 10, 37, 2, 155, 162,
            14, 253, 194, 205, 74, 106, 60, 205, 25, 53, 85, 144, 72, 11, 7,
            133, 78, 149, 111, 0, 215, 174, 36, 104, 175, 62, 196, 197, 49,
            78, 172, 146, 82, 216, 160, 45, 48, 212, 50, 168, 208, 255, 205,
            82, 22, 11, 13, 156, 197, 42, 159, 26, 124, 237, 18, 131, 239,
            186, 37, 96, 24, 154, 243, 202, 252, 87, 102, 23, 19, 29, 73,
            130, 95, 45, 219, 104, 13, 54, 32, 165, 144, 223, 14, 14, 169,
            100, 111, 246, 54, 185, 47, 156, 238, 249, 88, 33, 244, 135,
            233, 102, 36, 86, 196, 143, 178, 176, 62, 24, 178, 209, 163,
            244, 116, 236, 81, 177, 190, 205, 140, 230, 6, 113, 158, 105,
            111, 123,
        ]
    }
}

private extension Array where Element == UInt8 {
    var lengthField: [UInt8] {
        var count = self.count

        if count < 128 {
            return [ UInt8(count) ]
        }

        // The number of bytes needed to encode count.
        let lengthBytesCount = Int((log2(Double(count)) / 8) + 1)

        // The first byte in the length field encoding the number of remaining bytes.
        let firstLengthFieldByte = UInt8(128 + lengthBytesCount)

        var lengthField: [UInt8] = []
        for _ in 0..<lengthBytesCount {
            // Take the last 8 bits of count.
            let lengthByte = UInt8(count & 0xff)
            // Add them to the length field.
            lengthField.insert(lengthByte, at: 0)
            // Delete the last 8 bits of count.
            count = count >> 8
        }

        // Include the first byte.
        lengthField.insert(firstLengthFieldByte, at: 0)

        return lengthField
    }
}
