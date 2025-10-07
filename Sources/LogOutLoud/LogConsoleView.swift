//
//  LogConsoleView.swift
//  LogOutLoud
//
//  Created by Codex on 05/05/2025.
//

import SwiftUI

private struct LogConsoleStoreKey: EnvironmentKey {
    static let defaultValue: LogConsoleStore? = nil
}

public extension EnvironmentValues {
    var logConsole: LogConsoleStore? {
        get { self[LogConsoleStoreKey.self] }
        set { self[LogConsoleStoreKey.self] = newValue }
    }
}

public extension View {
    /// Injects a console store into the environment, enabling ``LogConsolePanel`` and custom UIs.
    func logConsole(_ store: LogConsoleStore?) -> some View {
        environment(\.logConsole, store)
    }

    /// Convenience to enable the default log console, wiring up the shared ``Logger`` sink on demand.
    @ViewBuilder
    @MainActor
    func logConsole(
        enabled: Bool = true,
        logger: Logger = .shared,
        maxEntries: Int = LogConsoleStore.defaultMaxEntries
    ) -> some View {
        if enabled {
            let store = logger.enableConsole(maxEntries: maxEntries)
            self.logConsole(store)
        } else {
            self.logConsole(nil)
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0,*)
public struct LogConsolePanel: View {
    @Environment(\.logConsole) private var store

    public init() {}

    public var body: some View {
        if let store {
            LogConsoleView(store: store)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "rectangle.and.text.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("Log console disabled")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Call .logConsole(enabled:) or inject a LogConsoleStore into the environment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 10.0, *)
public struct LogConsoleView: View {
    @ObservedObject private var store: LogConsoleStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedLevels: Set<LogLevel> = Set(LogLevel.allCases)
    @State private var searchText = ""
    @State private var autoScroll = true
    @State private var showClearConfirmation = false
    @State private var pauseUpdates = false
    @State private var showMetadata = true
    @State private var showTimestamps = true
    @State private var pausedEntries: [LogEntry] = []

    public init(store: LogConsoleStore) {
        self._store = ObservedObject(wrappedValue: store)
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                logContent
            }
            .searchable(text: $searchText, prompt: "Search")
        }
        .background(backgroundColor)
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .automatic) {
                levelMenu()
            }
            ToolbarItem(placement: .automatic) {
                optionsMenu(exportString: exportText())
            }
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .tint(.red)
                .confirmationDialog(
                    "Clear log entries?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete all entries", role: .destructive) {
                        store.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
#else
            ToolbarItem(placement: .bottomBar) {
                if #available(iOS 16.4, tvOS 16.4, *) {
                    levelMenu()
                        .menuActionDismissBehavior(.disabled)
                } else {
                    levelMenu()
                }
            }
            ToolbarItem(placement: .navigation) {
                let exportString = exportText()
                if #available(iOS 16.4, tvOS 16.4, *) {
                    optionsMenu(exportString: exportString)
                        .menuActionDismissBehavior(.disabled)
                } else {
                    optionsMenu(exportString: exportString)
                }
            }
            if #available(iOS 26, tvOS 26, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .tint(.red)
                .confirmationDialog(
                    "Clear log entries?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete all entries", role: .destructive) {
                        store.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
#endif
        }
    }


    private var logContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredEntries) { entry in
                        entryRow(entry)
                            .id(entry.id)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .background(secondaryBackgroundColor)
            .onChange(of: filteredEntries.last?.id) { id in
                guard autoScroll, !pauseUpdates, let id else { return }
                withAnimation(.easeOut) {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var filteredEntries: [LogEntry] {
        let baseEntries = pauseUpdates ? pausedEntries : store.entries
        return baseEntries.filter { entry in
            let levelMatch = selectedLevels.contains(entry.level)
            let searchMatch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchMatch = true
            } else {
                let needle = searchText
                searchMatch = entry.composedLine.localizedCaseInsensitiveContains(needle)
            }
            return levelMatch && searchMatch
        }
    }

    @ViewBuilder
    private func optionsMenu(exportString: String) -> some View {
        Menu("Options", systemImage: "ellipsis") {
            Toggle("Auto-Scroll", systemImage: "arrow.down.to.line", isOn: $autoScroll)
            Toggle(
                pauseUpdates ? "Resume Updates" : "Pause Updates",
                systemImage: pauseUpdates ? "playpause.fill" : "pause.circle",
                isOn: Binding(
                    get: { pauseUpdates },
                    set: { newValue in
                        pauseUpdates = newValue
                        if newValue {
                            pausedEntries = store.entries
                        } else {
                            pausedEntries.removeAll(keepingCapacity: false)
                        }
                    }
                )
            )
            Toggle("Show Metadata", systemImage: "curlybraces", isOn: $showMetadata)
            Toggle("Show Timestamps", systemImage: "clock", isOn: $showTimestamps)
            Divider()
            Button {
                copyVisibleEntries()
            } label: {
                Label("Copy Visible Entries", systemImage: "doc.on.doc")
            }
            .disabled(filteredEntries.isEmpty)
            if !exportString.isEmpty {
                ShareLink(item: exportString) {
                    Label("Export…", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func exportText() -> String {
        filteredEntries
            .map { formattedLine(for: $0) }
            .joined(separator: "\n")
    }

    private func copyVisibleEntries() {
        let text = exportText()
        guard !text.isEmpty else { return }
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
    }

    private func formattedLine(for entry: LogEntry) -> String {
        var components: [String] = []

        if showTimestamps {
            components.append(Self.timestampFormatter.string(from: entry.timestamp))
        }

        components.append(entry.level.displayName)
        components.append(entry.taggedMessage)

        if showMetadata, let metadata = entry.renderedMetadata {
            components.append(metadata)
        }

        return components.joined(separator: " | ")
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.07, green: 0.07, blue: 0.08) : Color(red: 0.96, green: 0.97, blue: 0.98)
    }

    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.92, green: 0.93, blue: 0.95)
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.16, green: 0.16, blue: 0.19) : Color.white
    }

    @ViewBuilder
    private func levelMenu() -> some View {
        Menu {
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    toggle(level)
                } label: {
                    HStack {
                        if selectedLevels.contains(level) {
                            Image(systemName: "checkmark")
                        }
                        Text(level.displayName)
                    }
                }
            }
            Divider()
            ControlGroup {
                Button("All", systemImage: "checkmark.circle") {
                    selectedLevels = Set(LogLevel.allCases)
                }
                Button("None", systemImage: "circle.slash") {
                    selectedLevels.removeAll()
                }
            }
        } label: {
            Label("Levels", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func toggle(_ level: LogLevel) {
        if selectedLevels.contains(level) {
            selectedLevels.remove(level)
        } else {
            selectedLevels.insert(level)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if showTimestamps {
                    Text(Self.timestampFormatter.string(from: entry.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Text(entry.level.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(levelColor(for: entry.level))

                Spacer()

                Text("\(entry.source.file):\(entry.source.line)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(entry.taggedMessage)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)

            if showMetadata, let metadata = entry.renderedMetadata {
                Text(metadata)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardBackgroundColor)
        )
    }

    private func levelColor(for level: LogLevel) -> Color {
        switch level {
        case .debug:
            return .gray
        case .info:
            return .blue
        case .notice:
            return .teal
        case .warning:
            return .yellow
        case .error:
            return .orange
        case .fault:
            return .red
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.locale = Locale.current
        return formatter
    }()
}

private extension LogLevel {
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .notice: return "Notice"
        case .warning: return "Warning"
        case .error: return "Error"
        case .fault: return "Fault"
        }
    }
}

#if DEBUG && canImport(SwiftUI)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct LogConsolePanel_Previews: PreviewProvider {
    @MainActor
    static func makeStore() -> LogConsoleStore {
        let store = LogConsoleStore(maxEntries: 200)

        let samples: [LogEntry] = {
            let lifecycleMetadata: LogMetadata = [
                "mode": .string("debug"),
                "version": .string("1.0.0")
            ]
            let networkMetadata: LogMetadata = ["latency_ms": .integer(850)]
            let parsingMetadata: LogMetadata = [
                "status": .integer(500),
                "endpoint": .string("/v1/profile"),
                "retry": .bool(false)
            ]

            let lifecycleEntry = LogEntry(
                level: .info,
                message: "Application initialised",
                tags: [Tag("Lifecycle")],
                metadata: lifecycleMetadata,
                renderedMetadata: LogMetadataValue.dictionary(lifecycleMetadata).description,
                subsystem: "world.aethers.preview",
                category: "default",
                source: .init(file: "App.swift", function: "init()", line: 12)
            )

            let networkEntry = LogEntry(
                level: .warning,
                message: "Slow network response",
                tags: [Tag("Network")],
                metadata: networkMetadata,
                renderedMetadata: LogMetadataValue.dictionary(networkMetadata).description,
                subsystem: "world.aethers.preview",
                category: "default",
                source: .init(file: "NetworkClient.swift", function: "fetch()", line: 88)
            )

            let parsingEntry = LogEntry(
                level: .error,
                message: "Failed to decode payload",
                tags: [Tag("Parsing"), Tag("API")],
                metadata: parsingMetadata,
                renderedMetadata: LogMetadataValue.dictionary(parsingMetadata).description,
                subsystem: "world.aethers.preview",
                category: "default",
                source: .init(file: "ProfileService.swift", function: "loadProfile()", line: 132)
            )

            return [lifecycleEntry, networkEntry, parsingEntry]
        }()

        samples.forEach { store.append($0) }
        return store
    }

    static var previews: some View {
        LogConsolePanel()
            .logConsole(makeStore())
    }
}
#endif
