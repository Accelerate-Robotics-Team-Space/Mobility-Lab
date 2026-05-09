//
//  SecTrust+Extensions.swift
//  MobilityLab
//
//  Created by Josh Franco on 10/28/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

extension SecTrust {
    static func constructor(from certs: [SecCertificate]) -> SecTrust? {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        
        let status = SecTrustCreateWithCertificates(certs as AnyObject, policy, &trust)
        if status == errSecSuccess {
            return trust
        } else {
            logger.warn("Error Deciphering Trsut from Cert")
            return nil
        }
    }
    
    func evaluate(result: @escaping (Result<SecKey, Error>) -> Void) {
        DispatchQueue.global().async {
            SecTrustEvaluateAsyncWithError(self, DispatchQueue.global()) { evaluatedTrust, isSuccess, error in
                if let error = error {
                    logger.warn("Error Evaluating Trust: \(error.localizedDescription)")
                    result(.failure(error))
                } else if isSuccess {
                    if #available(iOS 14.0, *) {
                        guard let publicKey = SecTrustCopyKey(evaluatedTrust) else { return result(.failure(SecurityError.unknown)) }
                        result(.success(publicKey))
                    } else {
                        guard let publicKey = SecTrustCopyPublicKey(evaluatedTrust) else { return result(.failure(SecurityError.unknown)) }
                        result(.success(publicKey))
                    }
                } else {
                    result(.failure(SecurityError.unknown))
                }
            }
        }
    }
}
