//
//  SwiftLogIntegration.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

import Foundation
import Logging

/// A `swift-log` compatible handler that forwards messages into `LogOutLoud`.
public struct LogOutLoudLogHandler: LogHandler {
    private var backend: Logger
    public var metadata: Logging.Logger.Metadata
    public var logLevel: Logging.Logger.Level {
        didSet { applyAllowedLevels() }
    }

    public init(label: String) {
        self.backend = Logger.shared(for: label)
        self.metadata = [:]
        self.logLevel = .trace
        applyAllowedLevels()
    }

    public subscript(metadataKey key: String) -> Logging.Logger.MetadataValue? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata explicitMetadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard level >= logLevel else { return }

        var combinedMetadata = metadata
        if let explicitMetadata {
            combinedMetadata.merge(explicitMetadata, uniquingKeysWith: { _, new in new })
        }

        var payload: [String: CustomStringConvertible] = [:]
        for (key, value) in combinedMetadata {
            payload[key] = LogMetadataValue.fromLoggingMetadataValue(value)
        }

        var tags: [Tag] = []
        if !source.isEmpty {
            tags.append(Tag(source))
        }

        backend.log(
            message.description,
            level: LogLevel(from: level),
            tags: tags,
            metadata: payload,
            file: file,
            function: function,
            line: Int(line)
        )
    }

    private func applyAllowedLevels() {
        backend.setAllowedLevels(LogLevel.allowedSet(for: logLevel))
    }
}

public extension LoggingSystem {
    /// Boots the global `LoggingSystem` using `LogOutLoud` under the hood.
    static func bootstrapLogOutLoud(defaultLogLevel: Logging.Logger.Level = .info) {
        bootstrap { label in
            var handler = LogOutLoudLogHandler(label: label)
            handler.logLevel = defaultLogLevel
            return handler
        }
    }
}

private extension LogLevel {
    init(from level: Logging.Logger.Level) {
        switch level {
        case .trace, .debug:
            self = .debug
        case .info:
            self = .info
        case .notice:
            self = .notice
        case .warning:
            self = .warning
        case .error:
            self = .error
        case .critical:
            self = .fault
        }
    }

    static func allowedSet(for level: Logging.Logger.Level) -> Set<LogLevel> {
        switch level {
        case .trace:
            return Set(LogLevel.allCases)
        case .debug:
            return [.debug, .info, .notice, .warning, .error, .fault]
        case .info:
            return [.info, .notice, .warning, .error, .fault]
        case .notice:
            return [.notice, .warning, .error, .fault]
        case .warning:
            return [.warning, .error, .fault]
        case .error:
            return [.error, .fault]
        case .critical:
            return [.fault]
        }
    }
}

private extension LogMetadataValue {
    static func fromLoggingMetadataValue(_ value: Logging.Logger.MetadataValue) -> LogMetadataValue {
        switch value {
        case .string(let string):
            return .string(string)
        case .stringConvertible(let convertible):
            return .string(convertible.description)
        case .dictionary(let dictionary):
            let nested = dictionary.mapValues { LogMetadataValue.fromLoggingMetadataValue($0) }
            return .dictionary(nested)
        case .array(let array):
            let values = array.map { LogMetadataValue.fromLoggingMetadataValue($0) }
            return .array(values)
        }
    }
}
