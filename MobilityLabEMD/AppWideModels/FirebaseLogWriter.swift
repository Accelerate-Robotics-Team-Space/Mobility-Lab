//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FirebaseCrashlytics
import Foundation

class FirebaseLogWriter: LogWriter {
    private let minimumLogLevel: LogLevel

    init(minimumLogLevel: LogLevel = .warn) {
        self.minimumLogLevel = LogLevel.minimum(minimumLogLevel)
    }

    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        if minimumLogLevel.contains(logLevel) {
            Crashlytics.crashlytics().log(message)
        }
    }

    func writeMessage(_ message: LogMessage, logLevel: LogLevel) {
        if minimumLogLevel.contains(logLevel) {
            Crashlytics.crashlytics().log(message.name)
        }
    }
}
