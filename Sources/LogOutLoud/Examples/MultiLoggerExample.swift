//
//  MultiLoggerExample.swift
//  LogOutLoud Examples
//
//  Created by Codex on 10/05/2025.
//

#if os(iOS)

import SwiftUI

private extension Tag {
    static let network = Tag("Network")
    static let payments = Tag("Payments")
    static let analytics = Tag("Analytics")
}

@MainActor
final class MultiLoggerConsoleCoordinator: ObservableObject {
    let store: LogConsoleStore
    private var sinkTokens: [(logger: Logger, token: LogEventSinkToken)] = []

    init(loggers: [Logger], maxEntries: Int = LogConsoleStore.defaultMaxEntries) {
        store = LogConsoleStore(maxEntries: maxEntries)
        sinkTokens = loggers.map { logger in
            (logger, logger.addEventSink(store))
        }
    }

    deinit {
        for pair in sinkTokens {
            pair.logger.removeEventSink(pair.token)
        }
    }
}

@available(iOS 16.0, *)
public struct MultiLoggerExampleView: View {
    private let networkLogger: Logger
    private let paymentsLogger: Logger

    @StateObject private var consoleCoordinator: MultiLoggerConsoleCoordinator
    @State private var showConsole = false

    public init() {
        let networkLogger = Logger.shared(for: "world.aethers.logoutloud.examples.network")
        let paymentsLogger = Logger.shared(for: "world.aethers.logoutloud.examples.payments")

        self.networkLogger = networkLogger
        self.paymentsLogger = paymentsLogger

        _consoleCoordinator = StateObject(
            wrappedValue: MultiLoggerConsoleCoordinator(
                loggers: [Logger.shared, networkLogger, paymentsLogger],
                maxEntries: 400
            )
        )
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Live Console") {
                    Button {
                        showConsole = true
                    } label: {
                        Label("Open Combined Console", systemImage: "waveform.path.ecg")
                            .font(.callout)
                    }

                    Text("A single console store receives entries from `Logger.shared` plus two keyed loggers. Toggling filters in the console lets you explore the aggregated stream.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("App Logger (Logger.shared)") {
                    Button {
                        Logger.shared.log("User tapped primary action", level: .notice, tags: [.analytics])
                    } label: {
                        LogExampleRow(
                            title: "Notice Log",
                            subtitle: "Logger.shared, Tag: Analytics",
                            systemImage: "bell.badge",
                            accent: .indigo
                        )
                    }

                    Button {
                        Logger.shared.log(
                            "Top-level fault triggered",
                            level: .fault,
                            metadata: ["feature": "Checkout"]
                        )
                    } label: {
                        LogExampleRow(
                            title: "Fault Log",
                            subtitle: "Logger.shared, Level: .fault",
                            systemImage: "flame.fill",
                            accent: .red
                        )
                    }
                }

                Section("Network Logger") {
                    Button {
                        networkLogger.log(
                            "Request queued",
                            level: .info,
                            tags: [.network],
                            metadata: ["endpoint": "/v1/profile"]
                        )
                    } label: {
                        LogExampleRow(
                            title: "Info",
                            subtitle: "Network queue event",
                            systemImage: "antenna.radiowaves.left.and.right",
                            accent: .blue
                        )
                    }

                    Button {
                        networkLogger.log(
                            "Network latency warning",
                            level: .warning,
                            tags: [.network],
                            metadata: ["latency_ms": 820]
                        )
                    } label: {
                        LogExampleRow(
                            title: "Warning",
                            subtitle: "Latency exceeded budget",
                            systemImage: "timer",
                            accent: .orange
                        )
                    }
                }

                Section("Payments Logger") {
                    Button {
                        paymentsLogger.log(
                            "Authorisation complete",
                            level: .debug,
                            tags: [.payments],
                            metadata: ["tx": String(UUID().uuidString.prefix(8))]
                        )
                    } label: {
                        LogExampleRow(
                            title: "Debug",
                            subtitle: "Short metadata payload",
                            systemImage: "checkmark.shield",
                            accent: .green
                        )
                    }

                    Button {
                        paymentsLogger.log(
                            "Payment declined",
                            level: .error,
                            tags: [.payments],
                            metadata: [
                                "code": "card_declined",
                                "retryable": false
                            ]
                        )
                    } label: {
                        LogExampleRow(
                            title: "Error",
                            subtitle: "Includes structured metadata",
                            systemImage: "xmark.octagon",
                            accent: .pink
                        )
                    }
                }
            }
            .navigationTitle("Multiple Loggers")
            .listStyle(.insetGrouped)
            .sheet(isPresented: $showConsole) {
                NavigationStack {
                    LogConsolePanel()
                        .navigationTitle("Combined Console")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .logConsole(consoleCoordinator.store)
            }
        }
        .logConsole(consoleCoordinator.store)
        .onAppear(perform: configureLoggers)
    }

    private func configureLoggers() {
        Logger.shared.subsystem = Bundle.main.bundleIdentifier ?? "world.aethers.logoutloud.examples.app"
        networkLogger.subsystem = "world.aethers.logoutloud.examples.network"
        paymentsLogger.subsystem = "world.aethers.logoutloud.examples.payments"

        Logger.shared.setAllowedLevels(Set(LogLevel.allCases))
        networkLogger.setAllowedLevels(Set([.debug, .info, .notice, .warning, .error, .fault]))
        paymentsLogger.setAllowedLevels(Set([.info, .warning, .error, .fault]))

        Logger.shared.log("MultiLoggerExampleView appeared", level: .info, tags: [.analytics])
        networkLogger.log("Network logger ready", level: .debug, tags: [.network])
        paymentsLogger.log("Payments logger ready", level: .info, tags: [.payments])
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        MultiLoggerExampleView()
    }
}

#endif
