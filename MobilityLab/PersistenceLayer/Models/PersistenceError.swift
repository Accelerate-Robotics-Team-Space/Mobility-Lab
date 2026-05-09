//
//  PersistenceErr.swift
//  MobilityLab
//
//  Created by Josh Franco on 1/14/21.
//  Copyright © 2021 Atlas LiftTech. All rights reserved.
//

import Foundation

enum PersistenceError: Error {
    case noElementFound(String?)
	case noDatabaseFound
	case selfNotFound
	case typeCaseFailed
}

// MARK: - LocalizedError
extension PersistenceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noElementFound(let description):
            return if let description {
                "No Element Found in SQL Query: \(description)"
            } else {
                "No Element Found in SQL Query"
            }
        case .noDatabaseFound:
            return "No database / database queue / database pool found."
        case .selfNotFound:
            return "Self got deinited! Closure escaped!"
        case .typeCaseFailed:
            return "Type check failed."
        }
    }
}
