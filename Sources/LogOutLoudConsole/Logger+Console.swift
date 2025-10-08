import Foundation
import LogOutLoud

@MainActor
private enum LoggerConsoleRegistry {
    struct ConsoleContext {
        let store: LogConsoleStore
        let token: LogEventSinkToken
    }

    private static var contexts: [ObjectIdentifier: ConsoleContext] = [:]

    static func context(for logger: Logger) -> ConsoleContext? {
        contexts[ObjectIdentifier(logger)]
    }

    static func set(_ context: ConsoleContext?, for logger: Logger) {
        contexts[ObjectIdentifier(logger)] = context
    }
}

public extension Logger {
    @MainActor
    @discardableResult
    func enableConsole(maxEntries: Int = LogConsoleStore.defaultMaxEntries) -> LogConsoleStore {
        if let context = LoggerConsoleRegistry.context(for: self) {
            context.store.updateMaxEntries(maxEntries)
            return context.store
        }

        let store = LogConsoleStore(maxEntries: maxEntries)
        let token = addEventSink(store)
        LoggerConsoleRegistry.set(.init(store: store, token: token), for: self)
        return store
    }

    @MainActor
    func disableConsole() {
        guard let context = LoggerConsoleRegistry.context(for: self) else { return }
        removeEventSink(context.token)
        LoggerConsoleRegistry.set(nil, for: self)
    }

    @MainActor
    var consoleStore: LogConsoleStore? {
        LoggerConsoleRegistry.context(for: self)?.store
    }
}
