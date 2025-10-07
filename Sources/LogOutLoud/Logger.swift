//
//  Logger.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import Foundation
import os
#if canImport(os.signpost)
import os.signpost
#endif

/// A global, shared logger powered by Apple’s Unified Logging system (`os.Logger` on modern platforms, `os_log` elsewhere).
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
    // MARK: - Registry for Named Shared Logger Instances (Concurrency-safe for Swift 6)
    // The registry is encapsulated in a final class and marked @unchecked Sendable.
    final class LoggerRegistry: @unchecked Sendable {
        private var loggers: [String: Logger] = [:]
        private let queue = DispatchQueue(label: "world.aethers.logOutLoud.registry", attributes: .concurrent)

        func logger(for key: String) -> Logger {
            var logger: Logger?
            queue.sync { logger = loggers[key] }
            if let logger = logger {
                return logger
            } else {
                let newLogger = Logger(subsystem: key)
                queue.async(flags: .barrier) { self.loggers[key] = newLogger }
                return newLogger
            }
        }
    }
    private static let registry = LoggerRegistry()

    /// Access a shared logger for a given key (synchronous, concurrency-safe)
    /// - Parameter key: A unique string to identify the logger (e.g., subsystem, feature, or package name).
    /// - Returns: The shared logger for the given key.
    public static func shared(for key: String) -> Logger {
        registry.logger(for: key)
    }

    /// The singleton instance for global access (backward compatible).
    public static let shared = Logger()

    // MARK: - Instance Properties
    /// The subsystem used by `OSLog` (defaults to your bundle identifier or "LogKit").
    public var subsystem: String
    private var allowedLevels: Set<LogLevel>
    private let osLog: OSLog
    private let modernLogger: Any?
    private let queue = DispatchQueue(
        label: "world.aethers.logkit.logger.allowedLevels",
        attributes: .concurrent
    )
    private var sinks: [UUID: WeakSink] = [:]

    /// Creates a logger with a specific subsystem.
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "LogKit") {
        self.subsystem = subsystem
        self.allowedLevels = Set(LogLevel.allCases)
        self.osLog = OSLog(subsystem: subsystem, category: "default")
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            self.modernLogger = os.Logger(subsystem: subsystem, category: "default")
        } else {
            self.modernLogger = nil
        }
    }

    public typealias Message = () -> String
    /// Handle for unregistering added log sinks.
    public struct SinkToken: Hashable, Sendable {
        fileprivate let id: UUID
    }

    /// Registers an additional sink that will receive all log events.
    /// - Parameter sink: The sink instance to add.
    /// - Returns: A token that can be used to remove the sink.
    @discardableResult
    public func addSink(_ sink: LogSink) -> SinkToken {
        let id = UUID()
        let token = SinkToken(id: id)
        queue.async(flags: .barrier) {
            self.sinks[id] = WeakSink(value: sink)
        }
        return token
    }

    /// Removes a previously registered sink using its token.
    public func removeSink(_ token: SinkToken) {
        queue.async(flags: .barrier) {
            self.sinks[token.id] = nil
        }
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
        guard let prepared = queue.sync(execute: {
            prepareLog(
                message: message,
                level: level,
                tags: tags,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }) else { return }

        broadcast(prepared.event)
        send(prepared.line, level: level)
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
        let prepared = queue.sync {
            prepareLogs(
                messages: messages,
                level: level,
                tags: tags,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }

        guard !prepared.isEmpty else { return }

        for log in prepared {
            broadcast(log.event)
            send(log.line, level: level)
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @discardableResult
    public func logAsync(
        priority: TaskPriority? = nil,
        level: LogLevel,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        _ message: @escaping @Sendable () async -> String
    ) -> Task<Void, Never> {
        Task(priority: priority) { [weak self] in
            guard let self else { return }
            guard self.isLevelEnabled(level) else { return }
            let resolvedMessage = await message()
            self.log(
                resolvedMessage,
                level: level,
                tags: tags,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }

    private func send(_ logMessage: String, level: LogLevel) {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *),
           let modernLogger = modernLogger as? os.Logger {
            modernLogger.log(level: level.osLoggerLevel, "\(logMessage, privacy: .public)")
        } else {
            os_log(
                "%{public}@",
                log: osLog,
                type: level.osLogType,
                logMessage
            )
        }
    }

    private func isLevelEnabled(_ level: LogLevel) -> Bool {
        queue.sync {
            allowedLevels.isEmpty || allowedLevels.contains(level)
        }
    }

    private func formatTags(_ tags: [Tag]) -> String {
        guard !tags.isEmpty else { return "" }
        let tagPrefix = tags
            .map { "[\($0.rawValue)]" }
            .joined()
        return "\(tagPrefix) "
    }

    private func metadataPayload(
        metadata: [String: CustomStringConvertible],
        tags: [Tag],
        file: String,
        function: String,
        line: Int
    ) -> MetadataResult? {
        var structured: LogMetadata = metadata.reduce(into: [:]) { partialResult, element in
            partialResult[element.key] = LogMetadataValue.fromAny(element.value)
        }

        if !tags.isEmpty {
            let tagValues = tags.map { LogMetadataValue.string($0.rawValue) }
            structured["_tags"] = .array(tagValues)
        }

        if structured["_source"] == nil {
            structured["_source"] = .dictionary([
                "file": .string((file as NSString).lastPathComponent),
                "function": .string(function),
                "line": .integer(line)
            ])
        }

        if structured["_subsystem"] == nil {
            structured["_subsystem"] = .string(subsystem)
        }

        guard !structured.isEmpty else { return nil }
        let formatted = LogMetadataValue.dictionary(structured).description
        return MetadataResult(structured: structured, formatted: formatted)
    }

    private func composeLogLine(
        message: String,
        tagPrefix: String,
        metadataPayload: String?
    ) -> String {
        var components: [String] = []

        let messageComponent = tagPrefix + message
        if !messageComponent.trimmingCharacters(in: .whitespaces).isEmpty {
            components.append(messageComponent)
        } else if !tagPrefix.isEmpty {
            components.append(tagPrefix.trimmingCharacters(in: .whitespaces))
        }

        if let metadataPayload, !metadataPayload.isEmpty {
            components.append(metadataPayload)
        }

        return components.joined(separator: " | ")
    }

    private func broadcast(_ event: LogEvent) {
        let targets: [LogSink] = queue.sync {
            sinks.compactMap { $0.value.value }
        }

        guard !targets.isEmpty else { return }
        targets.forEach { $0.receive(event) }

        queue.async(flags: .barrier) {
            self.cleanupSinksLocked()
        }
    }

    private func prepareLog(
        message: Message,
        level: LogLevel,
        tags: [Tag],
        metadata: [String: CustomStringConvertible],
        file: String,
        function: String,
        line: Int
    ) -> PreparedLog? {
        guard allowedLevels.isEmpty || allowedLevels.contains(level) else {
            return nil
        }

        let tagPrefix = formatTags(tags)
        let metadataResult = metadataPayload(
            metadata: metadata,
            tags: tags,
            file: file,
            function: function,
            line: line
        )
        let resolvedMessage = message()
        let logLine = composeLogLine(
            message: resolvedMessage,
            tagPrefix: tagPrefix,
            metadataPayload: metadataResult?.formatted
        )

        let event = LogEvent(
            subsystem: subsystem,
            level: level,
            tags: tags,
            message: resolvedMessage,
            metadata: metadataResult?.structured,
            file: file,
            function: function,
            line: line,
            formatted: logLine
        )

        return PreparedLog(line: logLine, event: event)
    }

    private func prepareLogs(
        messages: [Message],
        level: LogLevel,
        tags: [Tag],
        metadata: [String: CustomStringConvertible],
        file: String,
        function: String,
        line: Int
    ) -> [PreparedLog] {
        guard allowedLevels.isEmpty || allowedLevels.contains(level) else {
            return []
        }

        let tagPrefix = formatTags(tags)
        let metadataResult = metadataPayload(
            metadata: metadata,
            tags: tags,
            file: file,
            function: function,
            line: line
        )

        return messages.map { closure in
            let resolved = closure()
            let logLine = composeLogLine(
                message: resolved,
                tagPrefix: tagPrefix,
                metadataPayload: metadataResult?.formatted
            )

            let event = LogEvent(
                subsystem: subsystem,
                level: level,
                tags: tags,
                message: resolved,
                metadata: metadataResult?.structured,
                file: file,
                function: function,
                line: line,
                formatted: logLine
            )

            return PreparedLog(line: logLine, event: event)
        }
    }

    private func cleanupSinksLocked() {
        sinks = sinks.filter { $0.value.value != nil }
    }

    private struct MetadataResult {
        let structured: LogMetadata
        let formatted: String
    }

    private struct PreparedLog {
        let line: String
        let event: LogEvent
    }

    private struct WeakSink {
        weak var value: LogSink?
    }

#if canImport(os.signpost)
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    @discardableResult
    public func beginSignpost(
        _ name: StaticString,
        id: OSSignpostID? = nil,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        message: @autoclosure () -> String = ""
    ) -> OSSignpostID {
        let signpostID = id ?? OSSignpostID(log: osLog)
        let payload = composeLogLine(
            message: message(),
            tagPrefix: formatTags(tags),
            metadataPayload: metadataPayload(
                metadata: metadata,
                tags: tags,
                file: file,
                function: function,
                line: line
            )?.formatted
        )

        os_signpost(.begin, log: osLog, name: name, signpostID: signpostID, "%{public}@", payload)
        return signpostID
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func endSignpost(
        _ name: StaticString,
        id: OSSignpostID,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        message: @autoclosure () -> String = ""
    ) {
        let payload = composeLogLine(
            message: message(),
            tagPrefix: formatTags(tags),
            metadataPayload: metadataPayload(
                metadata: metadata,
                tags: tags,
                file: file,
                function: function,
                line: line
            )?.formatted
        )

        os_signpost(.end, log: osLog, name: name, signpostID: id, "%{public}@", payload)
    }

    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    @discardableResult
    public func eventSignpost(
        _ name: StaticString,
        id: OSSignpostID? = nil,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        message: @autoclosure () -> String = ""
    ) -> OSSignpostID {
        let signpostID = id ?? OSSignpostID(log: osLog)
        let payload = composeLogLine(
            message: message(),
            tagPrefix: formatTags(tags),
            metadataPayload: metadataPayload(
                metadata: metadata,
                tags: tags,
                file: file,
                function: function,
                line: line
            )?.formatted
        )

        os_signpost(.event, log: osLog, name: name, signpostID: signpostID, "%{public}@", payload)
        return signpostID
    }
#endif
}
