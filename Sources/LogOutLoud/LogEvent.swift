//
//  LogEvent.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

import Foundation

/// Represents a single logging event emitted by ``Logger``.
public struct LogEvent: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let subsystem: String
    public let level: LogLevel
    public let tags: [Tag]
    public let message: String
    public let metadata: LogMetadata?
    public let file: String
    public let function: String
    public let line: Int
    public let formatted: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        subsystem: String,
        level: LogLevel,
        tags: [Tag],
        message: String,
        metadata: LogMetadata?,
        file: String,
        function: String,
        line: Int,
        formatted: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.level = level
        self.tags = tags
        self.message = message
        self.metadata = metadata
        self.file = file
        self.function = function
        self.line = line
        self.formatted = formatted
    }
}

/// Consumers conform to ``LogSink`` to receive log events for custom handling (e.g. in-app consoles).
public protocol LogSink: AnyObject {
    func receive(_ event: LogEvent)
}
