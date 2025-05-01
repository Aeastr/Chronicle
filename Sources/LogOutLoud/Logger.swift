//
//  Logger.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import os
import Foundation

/// A global, shared logger powered by `os_log`.
///
/// Use `Logger.shared` to emit messages from anywhere, filter
/// by levels at runtime, and tag or attach metadata to your logs.
///
/// ```swift
/// Logger.shared.subsystem = Bundle
///     .main.bundleIdentifier
/// Logger.shared.setAllowedLevels([.error, .fault])
/// Logger.shared.log("Something broke",
///                   level: .error,
///                   tags: [.network],
///                   metadata: ["id": userID])
/// ```
/// Logger is @unchecked Sendable because all mutable state is protected by a concurrent queue or is immutable.
public final class Logger: @unchecked Sendable {
    // MARK: - Registry for Named Shared Logger Instances (Concurrency-safe)
    actor LoggerRegistry {
        private var loggers: [String: Logger] = [:]
        func logger(for key: String) -> Logger {
            if let logger = loggers[key] {
                return logger
            } else {
                let logger = Logger(subsystem: key)
                loggers[key] = logger
                return logger
            }
        }
    }
    private static let registry = LoggerRegistry()

    /// Access a shared logger for a given key (async, concurrency-safe)
    /// - Parameter key: A unique string to identify the logger (e.g., subsystem, feature, or package name).
    /// - Returns: The shared logger for the given key.
    public static func shared(for key: String) async -> Logger {
        await registry.logger(for: key)
    }

    /// Convenience: Shared logger for package/module logs (update key as needed)
    public static func package() async -> Logger {
        await shared(for: "com.example.package")
    }
    /// Convenience: Shared logger for network logs
    public static func network() async -> Logger {
        await shared(for: "com.example.network")
    }

    /// The singleton instance for global access (backward compatible).
    public static let shared = Logger()

    // MARK: - Instance Properties
    /// The subsystem used by `OSLog` (defaults to your bundle identifier or "LogKit").
    public var subsystem: String
    private var allowedLevels: Set<LogLevel>
    private let osLog: OSLog
    private let queue = DispatchQueue(
        label: "com.logkit.logger.allowedLevels",
        attributes: .concurrent
    )

    /// Creates a logger with a specific subsystem.
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "LogKit") {
        self.subsystem = subsystem
        self.allowedLevels = Set(LogLevel.allCases)
        self.osLog = OSLog(subsystem: subsystem, category: "default")
    }

    
    public typealias Message = () -> String
    
    /// The singleton instance for global access.
    public static let shared = Logger()
    
    /// The subsystem used by `OSLog` (defaults to your
    /// bundle identifier or "LogKit").
    public var subsystem: String =
    Bundle.main.bundleIdentifier ?? "LogKit"
    
    private var allowedLevels: Set<LogLevel> =
    Set(LogLevel.allCases)
    private let osLog: OSLog
    private let queue = DispatchQueue(
        label: "com.logkit.logger.allowedLevels",
        attributes: .concurrent
    )
    
    /// Creates the shared logger with a default `OSLog`.
    private init() {
        osLog = OSLog(subsystem: subsystem,
                      category: "default")
    }
    
    /// Updates which log levels are emitted.
    ///
    /// - Parameter levels:
    ///   A set of levels to allow. If empty, all levels
    ///   are allowed.
    public func setAllowedLevels(_ levels: Set<LogLevel>) {
        queue.async(flags: .barrier) {
            self.allowedLevels = levels
        }
    }
    
    /// Logs a message if its level is allowed.
    ///
    /// - Parameters:
    ///   - message: A closure that returns the message to log.
    ///   - level: The severity level.
    ///   - tags: An array of `Tag` values for categorization.
    ///   - metadata: A dictionary of extra context.
    ///   - file: The file where the log is called
    ///           (default: `#file`).
    ///   - function: The function name
    ///               (default: `#function`).
    ///   - line: The line number (default: `#line`).
    public func log(
        _ message: @autoclosure Message,
        level: LogLevel,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        queue.sync {
            guard allowedLevels.isEmpty
                    || allowedLevels.contains(level)
            else {
                return
            }
            
            let tagString = tags
                .map { "[\($0.rawValue)]" }
                .joined()
            let metaString = metadata
                .map { "[\($0.key)=\($0.value)]" }
                .joined()
            let logMessage = "\(tagString)\(metaString) "
            + "\(message())"
            
            os_log("%{public}@", log: osLog,
                   type: level.osLogType,
                   logMessage)
        }
    }
    
    /// Logs multiple messages if their level is allowed.
    ///
    /// - Parameters:
    ///   - messages: One or more ``Message`` instances to be logged.
    ///   - level: The severity level.
    ///   - tags: An array of `Tag` values for categorization.
    ///   - metadata: A dictionary of extra context.
    ///   - file: The file where the log is called
    ///           (default: `#file`).
    ///   - function: The function name
    ///               (default: `#function`).
    ///   - line: The line number (default: `#line`).
    public func log(
        _ messages: Message...,
        level: LogLevel,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard allowedLevels.isEmpty || allowedLevels.contains(level) else {
            return
        }
        let tagString = tags.map { "[\($0.rawValue)]" }.joined()
        let metaString = metadata.map { "[\($0.key)=\($0.value)]" }.joined()
        // ------------------------------------
        
        for messageClosure in messages {
            let logMessage = "\(tagString)\(metaString) \(messageClosure())"
            
            // Log using os_log
            os_log(
                "%{public}@",
                log: osLog,
                type: level.osLogType,
                logMessage
            )
        }
    }
}
