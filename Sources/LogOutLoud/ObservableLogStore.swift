//
//  ObservableLogStore.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

#if canImport(Observation)
import Foundation
import Observation

/// An Observation-friendly log buffer for apps targeting iOS 17, macOS 14, tvOS 17, or watchOS 10.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@Observable
public final class ObservableLogStore: LogSink {
    public private(set) var events: [LogEvent]

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

    public func attach(to logger: Logger = .shared) {
        detach()
        self.logger = logger
        token = logger.addSink(self)
    }

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

    public func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.events.removeAll(keepingCapacity: true)
        }
    }
}
#endif
