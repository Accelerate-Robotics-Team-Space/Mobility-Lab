//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
enum ALTEnvironment {
    static var current: ALTEnvironment {
        #if DEV
        return .dev
        #elseif QA
        return .qa
        #elseif TEST
        return .test
        #else
        return .prod
        #endif
    }
    
    case dev
    case qa
    case test
    case prod
    
    var description: String {
        switch self {
        case .dev:
            return "Development"
        case .qa:
            return "QA"
        case .test:
            return "Test"
        case .prod:
            return "Production"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .dev:
            return "Dev"
        case .qa:
            return "QA"
        case .test:
            return "Test"
        case .prod:
            return "Prod"
        }
    }
}
// swiftlint:enable identifier_name
