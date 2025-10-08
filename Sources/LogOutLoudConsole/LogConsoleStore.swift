//
//  LogConsoleStore.swift
//  LogOutLoud
//
//  Created by Codex on 05/05/2025.
//

import Combine
import Foundation
import LogOutLoud

/// In-memory buffer of recent ``LogEntry`` values suitable for displaying in a UI console.
@MainActor
public final class LogConsoleStore: ObservableObject, LogEventSink, @unchecked Sendable {
    public static let defaultMaxEntries = 500

    @Published public private(set) var entries: [LogEntry]
    public private(set) var maxEntries: Int

    public convenience init() {
        self.init(maxEntries: LogConsoleStore.defaultMaxEntries)
    }

    public init(maxEntries: Int) {
        self.entries = []
        self.maxEntries = max(1, maxEntries)
    }

    /// Adjusts the maximum number of retained entries.
    public func updateMaxEntries(_ newValue: Int) {
        maxEntries = max(1, newValue)
        trimIfNeeded()
    }

    /// Removes all buffered entries.
    public func clear() {
        entries.removeAll(keepingCapacity: true)
    }

    nonisolated public func receive(_ entry: LogEntry) {
        Task { [weak self] in
            guard let self else { return }
            await self.append(entry)
        }
    }

    func append(_ entry: LogEntry) {
        entries.append(entry)
        trimIfNeeded()
    }

    private func trimIfNeeded() {
        let overflow = entries.count - maxEntries
        guard overflow > 0 else { return }
        entries.removeFirst(overflow)
    }
}
