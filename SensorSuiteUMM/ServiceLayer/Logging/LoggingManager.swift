//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
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
        logger = LoggingManager.buildDebugLogger(named: "stagLogger")
        #else
        logger = LoggingManager.buildReleaseLogger(named: "prodLogger")
        #endif
        
        proxy = LoggingProxy(sourceLogger: logger)
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
		let writer = ConsoleWriter(method: .nslog, modifiers: [modifier])

        return Logger(
            logLevels: [.all],
            writers: [writer, FirebaseLogWriter(), container.sentryLogger.resolve()],
            executionMethod: .synchronous(lock: NSRecursiveLock())
        )
    }
    
    static func buildReleaseLogger(named: String, container: Container = .shared) -> Logger {
        var queueLabel: String = "Production.logging"
        var writers: [any LogWriter] = [FirebaseLogWriter(), container.sentryLogger.resolve()]
        if let bundleID = Bundle.main.bundleIdentifier {
            queueLabel = bundleID
            let osLogWriter = OSLogWriter(subsystem: bundleID, category: "SensorSuite")
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
