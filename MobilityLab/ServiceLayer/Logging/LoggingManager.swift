//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Foundation

internal var logger = LoggingManager.shared.proxy

final class LoggingManager: Sendable {
    static let shared = LoggingManager()

    private let logger: Logger
    let proxy: LoggingProxy

    private init() {
#if DEV || QA
        logger = LoggingManager.buildDebugLogger(named: "devLogger")
#elseif TEST
        logger = LoggingManager.buildReleaseLogger(named: "testLogger", includeFileLog: true)
#else
        logger = LoggingManager.buildReleaseLogger(named: "prodLogger", includeFileLog: false)
#endif

        proxy = LoggingProxy(sourceLogger: logger)
    }

    func register(_ writers: (any LogWriter)...) {
        let additionalLoggers = Array(writers)
        proxy.sourceLogger.writers.append(contentsOf: additionalLoggers)
    }
}

private extension LoggingManager {
    /*
     log-level Definitions:
     debug   - Highly detailed information of a context
     info    - Summary information of a context
     event   - User driven interactions such as button taps, view transitions, selecting a cell
     warn    - An error occurred but it is recoverable
     error   - A non-recoverable error occurred
     */
    
    static func buildDebugLogger(named: String, container: Container = .shared) -> Logger {
        let modifier = EmojiModifier(name: named)
        let writer = ConsoleWriter(modifiers: [modifier])
        var writers: [any LogWriter] = [writer, container.firebaseLogger.resolve(), container.sentryLogger.resolve()]
        #if targetEnvironment(simulator)
        if let fileLogWriter = FileLogWriter() {
            writers.append(fileLogWriter)
        }
        #else
        if let fileLogWriter = FileLogWriter(modifiers: [CPULoadModifier()]) {
            writers.append(fileLogWriter)
        }
        #endif

        return Logger(
            logLevels: [.all],
            writers: writers,
            executionMethod: .synchronous(lock: NSRecursiveLock())
        )
    }

    static func buildReleaseLogger(named: String, includeFileLog: Bool, container: Container = .shared) -> Logger {
        var queueLabel: String = "Production.logging"
        var writers: [any LogWriter] = [container.firebaseLogger.resolve(), container.sentryLogger.resolve()]
        if includeFileLog, let fileLogWriter = FileLogWriter() {
            writers.append(fileLogWriter)
        }
        if let bundleID = Bundle.main.bundleIdentifier {
            queueLabel = bundleID
            let osLogWriter = OSLogWriter(subsystem: bundleID, category: "MobilityLab")
            writers.append(osLogWriter)
        }
        let logLvls: LogLevel = [.event, .info, .warn, .error]
        let loggerQueue = DispatchQueue(label: "\(queueLabel).logging", qos: .utility)
        let asyncExecution: Logger.ExecutionMethod = .asynchronous(queue: loggerQueue)

        return Logger(
            logLevels: logLvls,
            writers: writers,
            executionMethod: asyncExecution
        )
    }
}
