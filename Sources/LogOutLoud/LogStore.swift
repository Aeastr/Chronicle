//
//  LogStore.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

import Combine
import Foundation

/// A Combine-friendly log buffer that mirrors events emitted by ``Logger``.
///
/// Use this in projects that still rely on `ObservableObject`. For modern
/// Observation-based apps, see ``ObservableLogStore``.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class LogStore: ObservableObject, LogSink {
    @Published public private(set) var events: [LogEvent]

    private let capacity: Int
    private weak var logger: Logger?
    private var token: Logger.SinkToken?

    public init(capacity: Int = 500) {
        self.capacity = capacity
        self.events = []
    }

    deinit {
        detach()
    }

    /// Attach this store to a logger instance. When attached, new events will
    /// append to the published `events` array (bounded by `capacity`).
    public func attach(to logger: Logger = .shared) {
        detach()
        self.logger = logger
        token = logger.addSink(self)
    }

    /// Detach this store from its logger and stop receiving updates.
    public func detach() {
        if let token, let logger {
            logger.removeSink(token)
        }
        token = nil
        logger = nil
    }

    public func receive(_ event: LogEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.events.append(event)
            if self.events.count > self.capacity {
                self.events.removeFirst(self.events.count - self.capacity)
            }
        }
    }

    /// Clears all buffered events.
    public func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.events.removeAll(keepingCapacity: true)
        }
    }
}
