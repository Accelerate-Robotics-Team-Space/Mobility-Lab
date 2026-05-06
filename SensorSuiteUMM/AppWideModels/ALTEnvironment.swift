//
//  ALTEnvironment.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

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
    case qa // swiftlint:disable:this identifier_name
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
