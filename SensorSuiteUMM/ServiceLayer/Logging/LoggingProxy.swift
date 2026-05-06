//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

struct LoggingProxy: Sendable {
    var sourceLogger: Logger
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.debugMessage(frame: frame, message)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.infoMessage(frame: frame, message)
    }

    func event(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.eventMessage(frame: frame, message)
    }

    func warn(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.warnMessage(frame: frame, message)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.errorMessage(frame: frame, message)
    }

    func logMessage(_ message: String, level: LogLevel, file: String = #file, function: String = #function, line: UInt = #line) {
        let message = format(message: message, file: file, function: function, line: line)
        let frame = Frame(file: file, function: function, line: line)
        sourceLogger.logMessage({ message }, with: level, frame: frame)
    }
}

private extension LoggingProxy {
    func format(message: String, file: String, function: String, line: UInt) -> String {
        #if DEV || QA /* I use os_log in production where line numbers and functions are discouraged */
        return "[\(sourceFileName(filePath: file)) \(function):\(line)] \(message)"
        #elseif TEST
        return "[\(sourceFileName(filePath: file)) \(function):\(line)] \(message)"
        #else
        return message
        #endif
    }
    
    func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}
