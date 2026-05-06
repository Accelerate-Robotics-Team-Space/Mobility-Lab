//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import Sentry

protocol SentryLoggerProtocol: ErrorLogWriter, AnyObject {
    func start()
    func enrichWith(tags: [String: String])
}

extension Container {
    var sentryLogger: Factory<SentryLoggerProtocol> {
        self { SentryLogWriter() }.cached
    }
}

final class SentryLogWriter: SentryLoggerProtocol {
    private let minimumLogLevel: LogLevel
    private let minimumEventLevel: LogLevel

    private var attributes: [String: String] = [:]

    fileprivate init(minimumLogLevel: LogLevel = .info, minimumEventLevel: LogLevel = .event) {
        self.minimumLogLevel = LogLevel.minimum(minimumLogLevel)
        self.minimumEventLevel = LogLevel.minimum(minimumEventLevel)
    }

    func start() {
        guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String else {
            logger.error("Could not find SENTRY_DSN in Info.plist")
            return
        }

        let environment = (Bundle.main.infoDictionary?["SENTRY_ENVIRONMENT"] as? String) ?? "production"

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.enableCaptureFailedRequests = true
            options.enableCrashHandler = true
            options.enableNetworkTracking = true
            options.enableSwizzling = true
            // options.failedRequestStatusCodes = HttpStatusCodeRange(min: 400, max: 599)
            // options.inAppExcludes = ["firebase"]
            // options.inAppIncludes = ["example.com"]
            options.sendDefaultPii = true
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // Sentry recommend adjusting this value in production.
            options.tracesSampleRate = 10.0
            options.debug = false // Enabled debug when first installing is always helpful
            options.experimental.enableLogs = true

            #if os(iOS)
            options.enableAppHangTrackingV2 = true
            options.enableUserInteractionTracing = true
            options.sessionReplay.quality = .low
            options.sessionReplay.onErrorSampleRate = 1.0
            options.sessionReplay.sessionSampleRate = 0.1
            options.attachScreenshot = false
            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 10.0
                $0.lifecycle = .trace
            }
            #endif
        }
    }

    func enrichWith(tags: [String: String]) {
        SentrySDK.configureScope { scope in
            for tag in tags {
                scope.setTag(value: tag.value, key: tag.key)
            }
        }
        self.attributes.merge(tags, uniquingKeysWith: { left, _ in left })
    }

    func writeError(_ error: any Error, logLevel: LogLevel, frame: Frame?) {
        if minimumEventLevel.contains(logLevel) {
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(SentryLevel(logLevel))
            }
        }

        if minimumLogLevel.contains(logLevel) {
            let logMessage: SentryLogMessage = "Error: \(error.localizedDescription) :: \("\(error)")"
            switch logLevel {
            case .debug:
                SentrySDK.logger.debug(logMessage, attributes: attributes)
            case .info:
                SentrySDK.logger.info(logMessage, attributes: attributes)
            case .warn:
                SentrySDK.logger.warn(logMessage, attributes: attributes)
            case .error:
                SentrySDK.logger.error(logMessage, attributes: attributes)
            default:
                break
            }
        }
    }

    func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        if minimumEventLevel.contains(logLevel) {
            SentrySDK.capture(message: message) { scope in
                scope.setLevel(SentryLevel(logLevel))
            }
        }

        if minimumLogLevel.contains(logLevel) {
            switch logLevel {
            case .debug:
                SentrySDK.logger.debug(message, attributes: attributes)
            case .info:
                SentrySDK.logger.info(message, attributes: attributes)
            case .warn:
                SentrySDK.logger.warn(message, attributes: attributes)
            case .error:
                SentrySDK.logger.error(message, attributes: attributes)
            default:
                break
            }
        }
    }
}

private extension SentryLevel {
    init(_ level: LogLevel) {
        switch level {
        case .debug:
            self = .debug
        case .info, .event:
            self = .info
        case .warn:
            self = .warning
        case .error:
            self = .error
            // SentryLevel.fatal is unused
        default:
            assertionFailure("Unexpected LogLevel")
            self = .debug
        }
    }
}
