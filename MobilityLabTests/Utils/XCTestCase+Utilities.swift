//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    /// Waits for a notification with the specified name and optional object to be posted.
    /// - Parameters:
    ///   - name: The name of the notification to wait for.
    ///   - object: The object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
    ///   - timeout: The maximum time to wait for the notification.
    ///   - handler: An optional closure to filter the notification. Return true to fulfill the expectation.
    /// - Returns: The received notification if it was delivered within the timeout, otherwise nil.
    func waitForNotification(
        _ name: Notification.Name,
        object: AnyObject? = nil,
        timeout: TimeInterval = 1.0,
        handler: ((Notification) -> Bool)? = nil
    ) -> Notification? {
        var receivedNotification: Notification?
        let expectation = self.expectation(forNotification: name, object: object) { notification in
            if let handler = handler {
                let result = handler(notification)
                if result {
                    receivedNotification = notification
                }
                return result
            } else {
                receivedNotification = notification
                return true
            }
        }
        wait(for: [expectation], timeout: timeout)
        return receivedNotification
    }
    
    /// Executes a throwing expression and fails the test if an error is thrown.
    /// - Parameters:
    ///   - block: The throwing expression to execute.
    ///   - file: The file name where failure is reported.
    ///   - line: The line number where failure is reported.
    /// - Returns: The value returned by the block if no error is thrown, otherwise nil.
    func expectNoThrow<T>(
        _ block: @autoclosure () throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T? {
        do {
            return try block()
        } catch {
            XCTFail("Unexpected error thrown: \(error)", file: file, line: line)
            return nil
        }
    }
    
    /// Converts an asynchronous callback-based completion into a synchronous wait.
    /// - Parameters:
    ///   - closure: The closure that accepts a completion handler to be called with the result.
    ///   - timeout: The maximum time to wait for the result.
    ///   - file: The file name where failure is reported.
    ///   - line: The line number where failure is reported.
    /// - Returns: The value passed to the completion handler if received within the timeout, otherwise nil.
    func awaitResult<T>(
        _ closure: (@escaping (T) -> Void) -> Void,
        timeout: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T? {
        var result: T?
        let expectation = self.expectation(description: "Awaiting result")
        
        closure { value in
            result = value
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        if result == nil {
            XCTFail("Timeout waiting for result", file: file, line: line)
        }
        
        return result
    }
}
