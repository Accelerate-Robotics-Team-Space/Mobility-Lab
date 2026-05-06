//
//  Keychain.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

protocol KeychainServiceProtocol {
    var deviceCertificate: SecCertificate? { get }
    var devicePublicKey: SecKey? { get set }
    var deviceCertIdentity: SecIdentity? { get set }
    var deviceIntermediateCert: SecCertificate? { get set }
    var accessToken: String? { get set }
    var certificateSerialNumber: String? { get }
    func reset()
}

extension KeychainServiceProtocol {
    var deviceCertificate: SecCertificate? {
        deviceCertIdentity?.certificate
    }
}

extension Container {
    var keychain: Factory<KeychainServiceProtocol> {
        self { Keychain.shared }.cached
    }
}

final class Keychain: KeychainServiceProtocol {
    // TODO: Deprecate static instance
    static let shared = Keychain()
    
    // MARK: - Init
    init() {}
    
    var accessToken: String? {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
                kSecAttrAccount as String: Keys.accessToken.rawValue,
                kSecReturnData as String: true,
            ]
            let accessTokenData: Data? = safeForceUnwrapTypeRef(getQuery(query))
            if let data = accessTokenData {
                return String(decoding: data, as: UTF8.self)
            } else {
                return nil
            }
        } set {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
                kSecAttrAccount as String: Keys.accessToken.rawValue,
            ]
            if let newAccessToken = newValue {
                if accessToken == nil {
                    query[kSecValueData as String] = newAccessToken.data(using: .utf8)!
                    saveQuery(query)
                } else {
                    let updateFields = [
                        kSecValueData: newAccessToken.data(using: .utf8)!
                    ] as CFDictionary
                    updateQuery(query, updateFields)
                }
            } else {
                deleteQuery(query)
            }
        }
    }

    var deviceCertIdentity: SecIdentity? {
        get {
            let query: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                        kSecAttrLabel as String: Keys.deviceCertIdentity.rawValue,
                                        kSecReturnRef as String: kCFBooleanTrue ?? true,
                                        kSecMatchLimit as String: kSecMatchLimitAll, ]

            if let identityArr = getQuery(query) as? [SecIdentity] {
                return identityArr.last
            } else {
                return safeForceUnwrapTypeRef(getQuery(query))
            }
        } set {
            var query: [String: Any] = [kSecAttrLabel as String: Keys.deviceCertIdentity.rawValue]
            
            if let newValue = newValue {
                query[kSecValueRef as String] = newValue
                saveQuery(query)
            } else {
                query[kSecClass as String] = kSecClassIdentity
                deleteQuery(query)
            }
        }
    }
    
    var deviceIntermediateCert: SecCertificate? {
        get {
            let query: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                        kSecAttrLabel as String: Keys.deviceIntCert.rawValue,
                                        kSecReturnRef as String: kCFBooleanTrue ?? true, ]

            return safeForceUnwrapTypeRef(getQuery(query))
        } set {
            var query: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                        kSecAttrLabel as String: Keys.deviceIntCert.rawValue, ]

            if let newValue = newValue {
                query[kSecValueRef as String] = newValue
                saveQuery(query)
            } else {
                deleteQuery(query)
            }
        }
    }
    
    var devicePublicKey: SecKey? {
        get {
            let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                        kSecAttrApplicationTag as String: Keys.devicePublicKey.rawValue,
                                        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                        kSecReturnRef as String: true, ]

            return safeForceUnwrapTypeRef(getQuery(query))
        } set {
            var query: [String: Any] = [kSecClass as String: kSecClassKey,
                                        kSecAttrApplicationTag as String: Keys.devicePublicKey.rawValue, ]
            if let newValue = newValue {
                query[kSecValueRef as String] = newValue
                saveQuery(query)
            } else {
                deleteQuery(query)
            }
        }
    }

    var certificateSerialNumber: String? {
        deviceCertificate?.serialNum
    }

    // MARK: - Util
    func reset() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
}

// MARK: - Private
private extension Keychain {
    enum Keys: String {
        case deviceCertIdentity
        case devicePublicKey
        case deviceCert
        case deviceIntCert
        case accessToken
    }
    
    func saveQuery(_ query: [String: Any]) {
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            let errMsg = SecCopyErrorMessageString(status, nil) ?? "?" as CFString
            logger.warn("Err saving to Keychain: \(errMsg)")
        }
    }
    
    func deleteQuery(_ query: [String: Any]) {
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            guard let errMsg = SecCopyErrorMessageString(status, nil) else { break }
            logger.warn("Err deleting to Keychain: \(errMsg)")
        }
    }
    
    func getQuery(_ query: [String: Any]) -> CFTypeRef? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item
        } else {
            let errMsg = SecCopyErrorMessageString(status, nil) ?? "?" as CFString
            logger.debug("Get Keychain Query Error: \(errMsg)")
            return nil
        }
    }
    
    func safeForceUnwrapTypeRef<T>(_ typeRef: CFTypeRef?) -> T? {
        if typeRef != nil {
            return typeRef as? T
        } else {
            return nil
        }
    }
    
    func updateQuery(_ query: [String: Any], _ updateField: CFDictionary) {
        let status = SecItemUpdate(query as CFDictionary, updateField)
        if status != errSecSuccess {
            let errMsg = SecCopyErrorMessageString(status, nil) ?? "?" as CFString
            logger.warn("Err updating to Keychain: \(errMsg)")
        }
    }
}
