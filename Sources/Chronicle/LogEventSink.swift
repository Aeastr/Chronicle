//
//  LogEventSink.swift
//  LogOutLoud
//
//  Created by Codex on 05/05/2025.
//

import Foundation

/// Closure signature for listening to ``LogEntry`` events.
public typealias LogEventHandler = @Sendable (LogEntry) -> Void

/// Token returned when registering an event sink. Use it to remove the sink later.
public struct LogEventSinkToken: Hashable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

/// Protocol for receiving live log entries emitted by ``Logger``.
public protocol LogEventSink: Sendable {
    func receive(_ entry: LogEntry)
}

struct AnyLogEventSink: @unchecked Sendable {
    let token: LogEventSinkToken
    private let handler: LogEventHandler

    init(token: LogEventSinkToken = LogEventSinkToken(), handler: @escaping LogEventHandler) {
        self.token = token
        self.handler = handler
    }

    init<S: LogEventSink>(_ sink: S) {
        let token = LogEventSinkToken()
        self.token = token
        self.handler = { entry in
            sink.receive(entry)
        }
    }

    func receive(_ entry: LogEntry) {
        handler(entry)
    }
}
