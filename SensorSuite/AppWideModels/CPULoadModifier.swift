//
//  CPULoadModifier.swift
//  SensorSuite
//
//  Copyright © 2025 Atlas LiftTech. All rights reserved.
//
import Foundation

public struct CPULoadModifier: LogModifier {
    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime] // e.g. "2025-07-15T08:30:00-07:00"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        return formatter
    }()

    public init() { }

    public func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
        // sample CPU & RAM
        let timestamp = timestampFormatter.string(from: .now)
        let cpu = String(format: "%.1f", Performance.currentCPUUsagePercent())
        let memBytes = Performance.memoryUsage()
        let mem = ByteCountFormatter.string(fromByteCount: Int64(memBytes.used), countStyle: .memory)

        let emoji = switch logLevel {
        case .debug: "🔬"
        case .info: "💡"
        case .event: "🔵"
        case .warn: "⚠️"
        case .error: "🆘"
        default: "[\(logLevel)]"
        }

        return "\(emoji) [\(timestamp)] [CPU: \(cpu)% MEM: \(mem)] \(message)\n"
    }
}
