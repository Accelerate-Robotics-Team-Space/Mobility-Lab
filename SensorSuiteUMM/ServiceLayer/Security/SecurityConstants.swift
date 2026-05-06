//
//  SecurityConstants.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Foundation

struct SecurityConstants {
    static var altSecret: String {
        #if DEV || QA
        return "For Common tables Some new Rand0m secret witch was really un expected by me @ this point of time oMg!"
        #elseif TEST
        return "AStaging It was getting dark, and we weren't there yet !24@ i like Dwali food ght it would be 5F@R"
        #else
        return "LPROD222It was getting dark, and we weren't there yet !24@ i like Dwali food ght it would be 5F@R"
        #endif
    }
}
