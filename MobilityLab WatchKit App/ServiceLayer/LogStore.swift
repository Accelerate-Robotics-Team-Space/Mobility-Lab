//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

class LogStore {
    static let shared = LogStore()
}

extension LogStore: LogWriter {
    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) { }

    func writeMessage(_ message: LogMessage, logLevel: LogLevel) { }
}
