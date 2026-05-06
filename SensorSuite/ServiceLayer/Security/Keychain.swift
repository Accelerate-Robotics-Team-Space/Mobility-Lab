//
//  Keychain.swift
//  SensorSuite
//
//  Created by Josh Franco on 10/12/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

#if os(iOS)
import FactoryKit
#endif
import Foundation

protocol KeychainProtocol: AnyObject {
    var deviceCertIdentity: SecIdentity? { get set }
    var deviceIntermediateCert: SecCertificate? { get set }
    var devicePublicKey: SecKey? { get set }
    var deviceId: String? { get set }
    var accessToken: String? { get set }
    var deviceCertificate: SecCertificate? { get }
    var certificateSerialNumber: String? { get }
    func reset()
}

#if os(iOS)
extension Container {
    var keychain: Factory<KeychainProtocol> {
        self { Keychain() }.cached
    }
}
#endif

final class Keychain: KeychainProtocol {
    // MARK: - Init
    fileprivate init() {}

    var deviceCertIdentity: SecIdentity? {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassIdentity,
                kSecAttrLabel as String: Keys.deviceCertIdentity.rawValue,
                kSecReturnRef as String: kCFBooleanTrue ?? true,
                kSecMatchLimit as String: kSecMatchLimitAll,
            ]

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

    var certificateSerialNumber: String? {
        deviceCertificate?.serialNum
    }

    var deviceIntermediateCert: SecCertificate? {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecAttrLabel as String: Keys.deviceIntCert.rawValue,
                kSecReturnRef as String: kCFBooleanTrue ?? true,
            ]

            return safeForceUnwrapTypeRef(getQuery(query))
        } set {
            var query: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecAttrLabel as String: Keys.deviceIntCert.rawValue,
            ]

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
            let query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: Keys.devicePublicKey.rawValue,
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecReturnRef as String: true,
            ]

            return safeForceUnwrapTypeRef(getQuery(query))
        } set {
            var query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: Keys.devicePublicKey.rawValue,
            ]
            if let newValue = newValue {
                query[kSecValueRef as String] = newValue
                saveQuery(query)
            } else {
                deleteQuery(query)
            }
        }
    }

    var deviceId: String? {
        get {
            getString(by: .deviceIdentifier)
        }
        set {
            guard let deviceId = newValue else { return }
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
                kSecAttrAccount as String: Keys.deviceIdentifier.rawValue,
                kSecValueData as String: deviceId.data(using: .utf8)!,
            ]
            saveQuery(query)
        }
    }
	
	var accessToken: String? {
		get {
            getString(by: .accessToken)
		}
        set {
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

    // MARK: - Computed Variables
    var deviceCertificate: SecCertificate? {
        deviceCertIdentity?.certificate
    }

    // MARK: - Util
    func reset() {
        let secItemClasses = [
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
        case deviceIdentifier
		case accessToken
    }

    func genericPasswordQuery(for key: Keys) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
        ]
    }

    func getString(by key: Keys) -> String? {
        let query: [String: Any] = genericPasswordQuery(for: key)
        let accessTokenData: Data? = safeForceUnwrapTypeRef(getQuery(query))
        if let data = accessTokenData {
            return String(decoding: data, as: UTF8.self)
        } else {
            return nil
        }
    }

    func saveQuery(_ query: [String: Any]) {
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            let errMsg = SecCopyErrorMessageString(status, nil) ?? "?" as CFString
            logger.warn("Err saving to Keychain: \(errMsg)")
        }
    }
	
	func updateQuery(_ query: [String: Any], _ updateField: CFDictionary) {
		let status = SecItemUpdate(query as CFDictionary, updateField)
		if status != errSecSuccess {
			let errMsg = SecCopyErrorMessageString(status, nil) ?? "?" as CFString
			logger.warn("Err updating to Keychain: \(errMsg)")
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
        guard let typeRef else {
            return nil
        }
        return typeRef as? T
    }
}
