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
                gradient: backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .modifier(ConditionalIgnoresSafeAreaModifier())
        )
        .onAppear {
            configureLogger()
        }
    }
    
    // MARK: - UI Components
    
    // Helper computed property for background gradient colors
    private var backgroundGradient: Gradient {
        #if os(macOS)
        let topColor = colorScheme == .dark ? Color.black : Color(NSColor.controlBackgroundColor) // NSColor available 10.10+
        let bottomColor = colorScheme == .dark ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor) // NSColor available 10.0+
        #else
        let topColor = colorScheme == .dark ? Color.black : Color(uiColor: .systemGray6)
        let bottomColor = colorScheme == .dark ? Color(uiColor: .systemGray6) : Color(uiColor: .systemBackground)
        #endif
        return Gradient(colors: [topColor, bottomColor])
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Wrap Image in availability check for macOS
            #if os(macOS)
            if #available(macOS 11.0, *) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .padding(.bottom, 4)
            } else {
                Text("(icon)") // Placeholder for macOS 10.15
                    .foregroundColor(.blue)
                    .padding(.bottom, 4)
            }
            #else // iOS, tvOS, watchOS
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.bottom, 4)
            #endif
            
            Text("LogOutLoud Test View")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tap buttons to generate logs. View output in Xcode console or Console.app.")
                .font(.caption)
                .modifier(SecondaryForegroundStyleModifier())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            
            Text("Subsystem: \(Logger.shared.subsystem)")
                .font(.caption)
                .modifier(SecondaryForegroundStyleModifier())
                .padding(.top, -4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(sectionBackgroundColor)
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
                .fill(sectionBackgroundColor)
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
                .fill(sectionBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var infoSection: some View {
        VStack {
            Text("Log Count: \(counter)")
                .font(.caption)
                .modifier(SecondaryForegroundStyleModifier())
            
            Text("Tap multiple times to see counter increment in logs")
                .font(.caption)
                .modifier(SecondaryForegroundStyleModifier())
        }
        .padding()
    }
    
    // Helper computed property for section background colors
    private var sectionBackgroundColor: Color {
        #if os(macOS)
        // Use available NSColors for macOS 10.15
        return colorScheme == .dark ? Color(NSColor.darkGray) : Color(NSColor.windowBackgroundColor)
        #else
        // Use UIColors for other platforms
        return colorScheme == .dark ? Color(uiColor: .systemGray5) : Color(uiColor: .systemBackground)
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func logButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Wrap Image in availability check for macOS
                #if os(macOS)
                if #available(macOS 11.0, *) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                } else {
                    Text("(i)") // Placeholder for macOS 10.15
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                }
                #else // iOS, tvOS, watchOS
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                #endif
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .modifier(SecondaryForegroundStyleModifier())
                }
                
                Spacer()
                
                // Wrap Image in availability check for macOS
                #if os(macOS)
                if #available(macOS 11.0, *) {
                     Image(systemName: "arrow.right.circle.fill")
                         .font(.system(size: 18))
                         .modifier(ArrowIconForegroundStyleModifier())
                } else {
                    Text(">") // Placeholder for macOS 10.15
                        .font(.system(size: 18))
                        .modifier(ArrowIconForegroundStyleModifier())
                }
                #else // iOS, tvOS, watchOS
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18))
                    .modifier(ArrowIconForegroundStyleModifier())
                #endif
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
        Logger.shared.subsystem = Bundle.main.bundleIdentifier ?? "com.example.logoutloud.test"
        Logger.shared.setAllowedLevels(Set(LogLevel.allCases))
        Logger.shared.log("LogTestView appeared", level: .info, tags: [.lifecycle])
        Logger.shared.speakLogsEnabled = true
        Logger.shared.speechRate = 0.7
        Logger.shared.speechPitch = 1.3
    }
}

// MARK: - Compatibility Modifiers

// Helper Modifier to conditionally apply ignoresSafeArea
struct ConditionalIgnoresSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        if #available(macOS 11.0, *) {
            content.ignoresSafeArea()
        } else {
            content // No equivalent for macOS 10.15
        }
        #elseif os(iOS)
        if #available(iOS 14.0, *) {
            content.ignoresSafeArea()
        } else {
            content // Not available before iOS 14
        }
        #elseif os(tvOS)
        if #available(tvOS 14.0, *) {
            content.ignoresSafeArea()
        } else {
            content // Not available before tvOS 14
        }
        #elseif os(watchOS)
        if #available(watchOS 7.0, *) {
            content.ignoresSafeArea()
        } else {
            content // Not available before watchOS 7
        }
        #else
        content
        #endif
    }
}

// Helper Modifier for Secondary Foreground Color Compatibility
struct SecondaryForegroundStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(watchOS) // watchOS has different availability
            if #available(watchOS 8.0, *) {
                content.foregroundColor(.secondary)
            } else {
                content // No direct equivalent on watchOS 6/7?
            }
        #elseif os(macOS)
            if #available(macOS 11.0, *) {
                content.foregroundColor(.secondary)
            } else {
                // Fallback for macOS 10.15
                content.foregroundColor(Color(NSColor.secondaryLabelColor))
            }
        #else // iOS, tvOS
            if #available(iOS 15.0, tvOS 15.0, *) {
                 content.foregroundStyle(.secondary) // Use newer API where available
            } else {
                 content.foregroundColor(.secondary) // Fallback for iOS 13/14
            }
        #endif
    }
}

// Helper Modifier for Arrow Icon Foreground Color Compatibility
struct ArrowIconForegroundStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        if #available(macOS 12.0, *) {
            // Use tertiaryLabelColor directly where available
            content.foregroundColor(Color(nsColor: .tertiaryLabelColor))
        } else {
            // Fallback for macOS 10.15/11
            content.foregroundColor(Color(NSColor.darkGray))
        }
        #else // iOS, tvOS, watchOS
        if #available(iOS 15.0, *) {
            // Use systemGray3 for other platforms
            content.foregroundColor(Color(uiColor: .systemGray3))
        }
        #endif
    }
}

@available(iOS 15.0, *)
struct LogOutLoud_ExampleView_Previews: PreviewProvider {
    static var previews: some View {
        LogOutLoud_ExampleView()
    }
}
