//
//  LogTestView.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import SwiftUI

extension Tag {
    static let ui = Tag("UI")
    static let data = Tag("Data")
    static let lifecycle = Tag("Lifecycle")
}


@available(iOS 15.0, *)
public struct LogOutLoud_ExampleView: View {
    @State private var counter = 0
    @Environment(\.colorScheme) private var colorScheme
    
    public init(){}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Info
                infoSection
                
                // Main content
                VStack(spacing: 16) {
                    basicLogsSection
                    advancedLogsSection
                }
                .padding(.horizontal)
                
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.black : Color(uiColor: .systemGray6),
                    colorScheme == .dark ? Color(uiColor: .systemGray6) : Color(uiColor: .systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            configureLogger()
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .padding(.bottom, 4)
            
            Text("LogOutLoud Test View")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tap buttons to generate logs. View output in Xcode console or Console.app.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            
            Text("Subsystem: \(Logger.shared.subsystem)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, -4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var basicLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Logs")
                .font(.headline)
                .padding(.bottom, 4)
            
            logButton(
                title: "Debug Log",
                subtitle: "UI Tag, Increases `counter`",
                icon: "ladybug",
                color: .blue
            ) {
                Logger.shared.log(
                    "Button tapped",
                    level: .debug,
                    tags: [.ui]
                )
                counter += 1
            }
            
            logButton(
                title: "Info Log",
                subtitle: "Data + Lifecycle Tags",
                icon: "info.circle",
                color: .green
            ) {
                Logger.shared.log(
                    "View appeared or data loaded",
                    level: .info,
                    tags: [.data, .lifecycle]
                )
            }
            
            logButton(
                title: "Warning Log",
                subtitle: "With Metadata: counter, user",
                icon: "exclamationmark.triangle",
                color: .yellow
            ) {
                Logger.shared.log(
                    "Potential issue detected",
                    level: .warning,
                    tags: [.data],
                    metadata: ["counter": counter, "user": "testUser"]
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 7, x: 0, y: 2)
        )
    }
    
    private var advancedLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Logs")
                .font(.headline)
                .padding(.bottom, 4)
            
            logButton(
                title: "Error Log",
                subtitle: "UI Tag",
                icon: "xmark.circle",
                color: .orange
            ) {
                Logger.shared.log(
                    "Simulated error condition!",
                    level: .error,
                    tags: [.ui]
                )
            }
            
            logButton(
                title: "Fault Log",
                subtitle: "Critical Issue",
                icon: "flame",
                color: .red
            ) {
                Logger.shared.log(
                    "Something went very wrong!",
                    level: .fault
                )
            }
            
            logButton(
                title: "Multiple Messages",
                subtitle: "Logs a sequence with metadata",
                icon: "list.bullet",
                color: .purple
            ) {
                Logger.shared.log(
                    { "First part of sequence" },
                    { "Second part, counter: \(counter)" },
                    { "Third part finished" },
                    level: .debug,
                    tags: [.lifecycle],
                    metadata: ["sequence": "A"]
                )
                counter += 1
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack {
            Text("Log Count: \(counter)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Tap multiple times to see counter increment in logs")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func logButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color(uiColor: .systemGray3))
                    .font(.system(size: 18))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    private func configureLogger() {
        Logger.shared.subsystem = Bundle.main.bundleIdentifier ?? "world.aethers.logoutloud.placeholder"
        Logger.shared.setAllowedLevels(Set(LogLevel.allCases))
        Logger.shared.log("LogTestView appeared", level: .info, tags: [.lifecycle])
    }
}
