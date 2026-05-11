//
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import Foundation
@testable import MobilityLab_BMM

final class MockFirebaseLogger: FirebaseLoggerProtocol {
    var startHandler: (() -> Void)?
    var enrichWithHandler: ((_ tags: [String: String]) -> Void)?
    var didCrashDuringPreviousExecutionHandler: (() -> Bool)?
    var writeMessageHandler: ((_ message: String, _ logLevel: LogLevel, _ frame: Frame?) -> Void)?
    var checkDidCrashHandler: (() -> Bool)?

    func start() {
        guard let startHandler else {
            fatalError("startHandler must be set")
        }
        startHandler()
    }
    
    func enrichWith(tags: [String: String]) {
        guard let enrichWithHandler else {
            fatalError("enrichWithHandler must be set")
        }
        enrichWithHandler(tags)
    }
    
    var didCrashDuringPreviousExecution: Bool {
        guard let didCrashDuringPreviousExecutionHandler else {
            fatalError("didCrashDuringPreviousExecutionHandler must be set")
        }
        return didCrashDuringPreviousExecutionHandler()
    }

    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        guard let writeMessageHandler else {
            fatalError("writeMessageHandler must be set")
        }
        writeMessageHandler(message, logLevel, frame)
    }

    @discardableResult
    func checkDidCrashDuringPreviousExecution() -> Bool {
        guard let checkDidCrashHandler else {
            fatalError("checkDidCrashHandler")
        }
        return checkDidCrashHandler()
    }
}

final class NullFirebaseLogger: FirebaseLoggerProtocol {
    func start() {
        fatalError("Null Service Should Not Be Used")
    }

    func enrichWith(tags: [String: String]) {
        fatalError("Null Service Should Not Be Used")
    }

    var didCrashDuringPreviousExecution: Bool {
        fatalError("Null Service Should Not Be Used")
    }

    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        fatalError("Null Service Should Not Be Used")
    }

    @discardableResult
    func checkDidCrashDuringPreviousExecution() -> Bool {
        fatalError("Null Service Should Not Be Used")
    }
}
