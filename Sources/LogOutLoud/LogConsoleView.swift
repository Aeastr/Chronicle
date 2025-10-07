//
//  LogConsoleView.swift
//  LogOutLoud
//
//  Created by Codex on 05/05/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public struct LogConsoleView: View {
    @ObservedObject private var store: LogConsoleStore

    @State private var selectedLevels: Set<LogLevel> = Set(LogLevel.allCases)
    @State private var searchText = ""
    @State private var autoScroll = true

    public init(store: LogConsoleStore) {
        self._store = ObservedObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 0) {
            controlBar
            Divider()
            logContent
        }
        .background(PlatformColor.background)
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            levelMenu

            searchField

            Toggle("Auto-Scroll", isOn: $autoScroll)
                .frame(maxWidth: 160)

            Spacer()

            Button {
                store.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(.thinMaterial)
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
            .background(PlatformColor.secondaryBackground)
            .onChange(of: filteredEntries.last?.id) { id in
                guard autoScroll, let id else { return }
                withAnimation(.easeOut) {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var filteredEntries: [LogEntry] {
        store.entries.filter { entry in
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

    private var levelMenu: some View {
        Menu {
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    toggle(level)
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .opacity(selectedLevels.contains(level) ? 1 : 0)
                        Text(level.displayName)
                    }
                }
            }
            Divider()
            Button("Select All") {
                selectedLevels = Set(LogLevel.allCases)
            }
            Button("Show None") {
                selectedLevels.removeAll()
            }
        } label: {
            Label("Levels", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25))
        )
        .frame(maxWidth: 240)
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
                Text(Self.timestampFormatter.string(from: entry.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

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

            if let metadata = entry.renderedMetadata {
                Text(metadata)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(PlatformColor.secondaryBackground.opacity(0.8))
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

private enum PlatformColor {
    static var background: Color {
        #if canImport(UIKit)
        if #available(iOS 15.0, tvOS 15.0, *) {
            return Color(uiColor: .systemBackground)
        } else {
            return Color(.systemBackground)
        }
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

    static var secondaryBackground: Color {
        #if canImport(UIKit)
        if #available(iOS 15.0, tvOS 15.0, *) {
            return Color(uiColor: .secondarySystemBackground)
        } else {
            return Color(.secondarySystemBackground)
        }
        #elseif canImport(AppKit)
        return Color(nsColor: .underPageBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }
}
