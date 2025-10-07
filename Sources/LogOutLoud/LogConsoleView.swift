//
//  LogConsoleView.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

import SwiftUI
#if canImport(Observation)
import Observation
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public struct LogConsoleView: View {
    @ObservedObject private var store: LogStore
    @State private var isPinnedToBottom = true

    public init(store: LogStore) {
        self.store = store
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(store.events) { event in
                        LogEventRow(event: event)
                            .id(event.id)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .onChange(of: store.events.count) { _ in
                guard isPinnedToBottom, let last = store.events.last else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            PinToggle(isPinned: $isPinnedToBottom)
                .padding(12)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct LogEventRow: View {
    let event: LogEvent

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        Text(line(for: event))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(color(for: event.level))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func line(for event: LogEvent) -> String {
        let timestamp = Self.timestampFormatter.string(from: event.timestamp)
        let level = event.levelDisplay
        return "[\(timestamp)] [\(level)] \(event.formatted)"
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .debug:
            return .gray
        case .info, .notice:
            return .green
        case .warning:
            return .yellow
        case .error:
            return .orange
        case .fault:
            return .red
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct PinToggle: View {
    @Binding var isPinned: Bool

    var body: some View {
        Button {
            isPinned.toggle()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin.slash")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isPinned ? Color.green : Color.gray)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private extension LogLevel {
    var levelDisplay: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        }
    }
}

#if canImport(Observation)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, *)
public struct ObservableLogConsoleView: View {
    @Bindable private var store: ObservableLogStore
    @State private var isPinnedToBottom = true

    public init(store: ObservableLogStore) {
        self.store = store
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(store.events) { event in
                        LogEventRow(event: event)
                            .id(event.id)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .onChange(of: store.events.count) { _ in
                guard isPinnedToBottom, let last = store.events.last else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            PinToggle(isPinned: $isPinnedToBottom)
                .padding(12)
        }
    }
}
#endif
