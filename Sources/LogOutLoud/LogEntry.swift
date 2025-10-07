//
//  LogEntry.swift
//  LogOutLoud
//
//  Created by Codex on 05/05/2025.
//

import Foundation

/// Represents a single log record emitted by ``Logger``.
public struct LogEntry: Identifiable, Hashable, Sendable {
    public struct Source: Hashable, Sendable {
        public let file: String
        public let function: String
        public let line: Int

        public init(file: String, function: String, line: Int) {
            self.file = file
            self.function = function
            self.line = line
        }
    }

    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let tags: [Tag]
    public let metadata: LogMetadata?
    public let renderedMetadata: String?
    public let subsystem: String
    public let category: String
    public let source: Source

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        tags: [Tag],
        metadata: LogMetadata?,
        renderedMetadata: String?,
        subsystem: String,
        category: String,
        source: Source
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.tags = tags
        self.metadata = metadata
        self.renderedMetadata = renderedMetadata
        self.subsystem = subsystem
        self.category = category
        self.source = source
    }

    /// Convenience summary such as `[Network][API] Message text`.
    public var taggedMessage: String {
        let prefix = tags.reduce(into: "") { partialResult, tag in
            partialResult.append("[\(tag.rawValue)]")
        }
        return prefix.isEmpty ? message : "\(prefix) \(message)"
    }

    /// The full line as forwarded to Unified Logging.
    public var composedLine: String {
        guard let renderedMetadata, !renderedMetadata.isEmpty else {
            return taggedMessage
        }
        return "\(taggedMessage) | \(renderedMetadata)"
    }
}

public extension LogEntry {
    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
