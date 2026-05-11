//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockSentryLogger: SentryLoggerProtocol {
    var startHandler: (() -> Void)?
    var enrichHandler: (([String: String]) -> Void)?
    var writeErrorHandler: ((any Error, LogLevel, Frame?) -> Void)?
    var writeMessageHandler: ((String, LogLevel, Frame?) -> Void)?

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func enrichWith(tags: [String: String]) {
        guard let enrichHandler else {
            fatalError("enrichHandler must be set")
        }
        enrichHandler(tags)
    }
    
    func writeError(_ error: any Error, logLevel: LogLevel, frame: Frame?) {
        guard let writeErrorHandler else {
            fatalError("writeErrorHandler must be set")
        }
        writeErrorHandler(error, logLevel, frame)
    }
    
    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        guard let writeMessageHandler else {
            fatalError("writeMessageHandler must be set")
        }
        writeMessageHandler(message, logLevel, frame)
    }
}

final class NullSentryLogger: SentryLoggerProtocol {
    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func enrichWith(tags: [String: String]) {
        fatalError("Null Service Should Not Be Used")
    }

    func writeError(_ error: any Error, logLevel: LogLevel, frame: Frame?) {
        fatalError("Null Service Should Not Be Used")
    }

    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        fatalError("Null Service Should Not Be Used")
    }
}
