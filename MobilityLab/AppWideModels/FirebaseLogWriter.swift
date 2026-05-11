//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import FactoryKit
import FirebaseCore
import FirebaseCrashlytics
import Foundation

protocol FirebaseLoggerProtocol: LogWriter, AnyObject {
    func start()
    func enrichWith(tags: [String: String])
    var didCrashDuringPreviousExecution: Bool { get }
    @discardableResult func checkDidCrashDuringPreviousExecution() -> Bool
}

extension Container {
    var firebaseLogger: Factory<FirebaseLoggerProtocol> {
        self { FirebaseLogWriter() }.cached
    }
}

final class FirebaseLogWriter: FirebaseLoggerProtocol {
    private let minimumLogLevel: LogLevel

    private(set) var didCrashDuringPreviousExecution: Bool = false

    fileprivate init(minimumLogLevel: LogLevel = .warn) {
        self.minimumLogLevel = LogLevel.minimum(minimumLogLevel)
    }

    func start() {
        FirebaseApp.configure()
    }

    @discardableResult
    func checkDidCrashDuringPreviousExecution() -> Bool {
        let didCrash = Crashlytics.crashlytics().didCrashDuringPreviousExecution()
        self.didCrashDuringPreviousExecution = didCrash
        return didCrash
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

    func enrichWith(tags: [String: String]) {
        for (key, value) in tags {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
    }
}
