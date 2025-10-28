//
//  SingleLoggerExample.swift
//  LogOutLoud Examples
//
//  Created by Codex on 10/05/2025.
//

#if os(iOS)

import SwiftUI
import Chronicle
import ChronicleConsole

private extension Tag {
    static let ui = Tag("UI")
    static let data = Tag("Data")
    static let lifecycle = Tag("Lifecycle")
}

@available(iOS 16.0, *)
public struct SingleLoggerExampleView: View {
    @State private var counter = 0
    @State private var showConsole = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Live Console") {
                    Button {
                        showConsole = true
                    } label: {
                        Label("Open Shared Console", systemImage: "waveform.path")
                            .font(.callout)
                    }

                    Text("Viewing logs emitted through `Logger.shared`. The button opens the SwiftUI console powered by the default store.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Quick Stats") {
                    Text("Emitted logs: \(counter)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Basic Logs") {
                    Button {
                        Logger.shared.log("Primary button tapped", level: .info, tags: [.ui])
                        counter += 1
                    } label: {
                        LogExampleRow(
                            title: "Info Log",
                            subtitle: "Tag: UI",
                            systemImage: "info.circle",
                            accent: .blue
                        )
                    }

                    Button {
                        Logger.shared.log("Counter incremented to \(counter + 1)", level: .debug, tags: [.data])
                        counter += 1
                    } label: {
                        LogExampleRow(
                            title: "Debug Log",
                            subtitle: "Tag: Data",
                            systemImage: "ladybug",
                            accent: .teal
                        )
                    }
                }

                Section("Advanced Logs") {
                    Button {
                        Logger.shared.log(
                            "Simulated recoverable error",
                            level: .error,
                            tags: [.ui]
                        )
                        counter += 1
                    } label: {
                        LogExampleRow(
                            title: "Error Log",
                            subtitle: "Level: .error",
                            systemImage: "exclamationmark.triangle",
                            accent: .orange
                        )
                    }

                    Button {
                        Logger.shared.log(
                            { "Request started" },
                            { "Intermediate step with counter = \(counter)" },
                            { "Request finished" },
                            level: .notice,
                            tags: [.lifecycle],
                            metadata: ["sequence": "A", "attempt": counter + 1]
                        )
                        counter += 1
                    } label: {
                        LogExampleRow(
                            title: "Chained Messages",
                            subtitle: "Logs three segments with metadata",
                            systemImage: "list.bullet.rectangle",
                            accent: .purple
                        )
                    }
                }
            }
            .navigationTitle("Single Logger")
            .listStyle(.insetGrouped)
            .sheet(isPresented: $showConsole) {
                NavigationStack {
                    LogConsolePanel()
                        .navigationTitle("Shared Console")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .logConsole(enabled: true)
            }
        }
        .logConsole(enabled: true)
        .onAppear(perform: configureLogger)
    }

    private func configureLogger() {
        Logger.shared.subsystem = Bundle.main.bundleIdentifier ?? "world.aethers.logoutloud.example"
        Logger.shared.setAllowedLevels(Set(LogLevel.allCases))
        Logger.shared.log("SingleLoggerExampleView appeared", level: .info, tags: [.lifecycle])
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        SingleLoggerExampleView()
    }
}

#endif
