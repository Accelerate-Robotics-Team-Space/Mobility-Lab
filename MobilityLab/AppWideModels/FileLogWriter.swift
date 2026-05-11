//
//  FileLogWriter.swift
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//

import Foundation

/// FileLogWriter writes log entries to a file.
public class FileLogWriter: LogWriter {
    private let directory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.file.logger", qos: .background)
    private let minimumLogLevel: LogLevel
    public var modifiers: [LogModifier]

    private static let fileExtension: String = "txt"

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime] // e.g. "2025-07-15T08:30:00-07:00"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        return formatter
    }()

    public init?(
        directory: URL? = nil,
        fileManager: FileManager = .default,
        minimumLogLevel: LogLevel = .debug,
        modifiers: [LogModifier] = []
    ) {
        self.fileManager = fileManager
        let fileDirectory = directory ?? fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appending(path: "Logs", directoryHint: .isDirectory)

        guard let fileDirectory else {
            return nil
        }
        self.directory = fileDirectory
        self.minimumLogLevel = LogLevel.minimum(minimumLogLevel)
        self.modifiers = modifiers
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    // Computes the log file URL based on today's date ("yyyy-MM-dd.txt").
    public func currentLogFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fileName = formatter.string(from: Date())
        return directory.appendingPathComponent(fileName).appendingPathExtension(Self.fileExtension)
    }

    public func write(_ message: String) {
        let logEntry = message + "\n"
        let fileURL = currentLogFileURL()

        queue.async {
            // ensure file
            if !self.fileManager.fileExists(atPath: fileURL.path) {
                self.fileManager.createFile(atPath: fileURL.path, contents: nil)
            }

            guard let data = logEntry.data(using: .utf8),
                  let handle = try? FileHandle(forWritingTo: fileURL) else {
                return
            }
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
    }
}

// MARK: - Willow.LogWriter Conformance
extension FileLogWriter: LogModifierWriter {
    public func writeMessage(_ message: String, logLevel: LogLevel, frame: Frame?) {
        if minimumLogLevel.contains(logLevel) {
            let message = modifyMessage(message, logLevel: logLevel)
            self.write(message)
        }
    }

    public func writeMessage(_ message: any LogMessage, logLevel: LogLevel) {
        if minimumLogLevel.contains(logLevel) {
            let formattedMessage = modifyMessage("\(message.name): \(message.attributes)", logLevel: logLevel)
            self.write(formattedMessage)
        }
    }
}
