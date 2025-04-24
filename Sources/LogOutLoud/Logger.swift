//
//  Logger.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import os
import Foundation
#if canImport(AVFoundation)
import AVFoundation // Needed for iOS/tvOS speech
#endif

/// A global, shared logger powered by `os_log`.
///
/// Use `Logger.shared` to emit messages from anywhere, filter
/// by levels at runtime, and tag or attach metadata to your logs.
///
/// ```swift
/// Logger.shared.subsystem = Bundle
///     .main.bundleIdentifier
/// Logger.shared.setAllowedLevels([.error, .fault])
/// Logger.shared.log("Something broke",
///                   level: .error,
///                   tags: [.network],
///                   metadata: ["id": userID])
/// ```
public final class Logger {
    
    public typealias Message = () -> String
    
    /// The singleton instance for global access.
    public static let shared = Logger()
    
    /// The subsystem used by `OSLog` (defaults to your
    /// bundle identifier or "LogKit").
    public var subsystem: String =
    Bundle.main.bundleIdentifier ?? "LogKit"
    
    /// Enables/disables speaking logs aloud using the 'say' command.
    public var speakLogsEnabled: Bool = false
    
    /// Optional voice identifier for text-to-speech.
    /// macOS: Use name from `say -v '?'` (e.g., "Alex").
    /// iOS/tvOS: Use identifier from `AVSpeechSynthesisVoice.speechVoices()` (e.g., "com.apple.speech.synthesis.voice.Alex").
    public var speechVoiceIdentifier: String?
    
    /// Optional speech rate. Default is platform-specific (usually 0.5 for iOS/tvOS).
    /// iOS/tvOS range: AVSpeechUtteranceMinimumSpeechRate (0.0) to AVSpeechUtteranceMaximumSpeechRate (1.0).
    /// macOS range: Converted to WPM for `say -r` (approx 50-350).
    public var speechRate: Float?
    
    /// Optional speech pitch multiplier. Default is 1.0.
    /// iOS/tvOS range: 0.5 to 2.0.
    /// macOS: Ignored by `say` command.
    public var speechPitch: Float?
    
    private var allowedLevels: Set<LogLevel> =
    Set(LogLevel.allCases)
    private let osLog: OSLog
    private let queue = DispatchQueue(
        label: "com.logkit.logger.allowedLevels",
        attributes: .concurrent
    )
    
    #if os(iOS) || os(tvOS)
    /// Speech synthesizer instance for iOS/tvOS.
    private let speechSynthesizer = AVSpeechSynthesizer()
    #endif
    
    /// Creates the shared logger with a default `OSLog`.
    private init() {
        osLog = OSLog(subsystem: subsystem,
                      category: "default")
    }
    
    /// Updates which log levels are emitted.
    ///
    /// - Parameter levels:
    ///   A set of levels to allow. If empty, all levels
    ///   are allowed.
    public func setAllowedLevels(_ levels: Set<LogLevel>) {
        queue.async(flags: .barrier) {
            self.allowedLevels = levels
        }
    }
    
    /// Logs a message if its level is allowed.
    ///
    /// - Parameters:
    ///   - message: A closure that returns the message to log.
    ///   - level: The severity level.
    ///   - tags: An array of `Tag` values for categorization.
    ///   - metadata: A dictionary of extra context.
    ///   - file: The file where the log is called
    ///           (default: `#file`).
    ///   - function: The function name
    ///               (default: `#function`).
    ///   - line: The line number (default: `#line`).
    public func log(
        _ message: @autoclosure Message,
        level: LogLevel,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        queue.sync {
            guard allowedLevels.isEmpty
                    || allowedLevels.contains(level)
            else {
                return
            }
            
            let actualMessage = message() // Evaluate the autoclosure once

            // Speak the log if enabled (platform-specific implementation)
            if speakLogsEnabled {
                #if os(macOS)
                // macOS: Use Process to call 'say' command
                DispatchQueue.global(qos: .background).async {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
                    // Base arguments
                    var args = [String]()
                    // Add voice if specified
                    if let voiceId = self.speechVoiceIdentifier {
                        args.append("-v")
                        args.append(voiceId)
                    }
                    // Add rate if specified (converting Float to WPM)
                    if let rate = self.speechRate {
                        let wpm = Int( min(350, max(50, 50 + (rate * 275))) ) // Map 0.0-1.0 -> 50-325 WPM, clamp
                        args.append("-r")
                        args.append("\(wpm)")
                    }
                    // Add message
                    args.append("\(level.rawValue): \(actualMessage)")
                    process.arguments = args
                    do {
                        try process.run()
                        process.waitUntilExit()
                    } catch {
                        os_log("Failed to execute 'say' command: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                    }
                }
                #elseif os(iOS) || os(tvOS)
                // iOS/tvOS: Use AVSpeechSynthesizer
                let utterance = AVSpeechUtterance(string: "\(level.rawValue): \(actualMessage)")
                // Set voice if specified
                if let voiceId = self.speechVoiceIdentifier {
                    utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
                }
                // Set rate if specified
                if let rate = self.speechRate {
                    utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate))
                }
                // Set pitch if specified
                if let pitch = self.speechPitch {
                    utterance.pitchMultiplier = max(0.5, min(2.0, pitch))
                }
                self.speechSynthesizer.speak(utterance)
                #endif
            }

            let tagString = tags
                .map { "[\($0.rawValue)]" }
                .joined()
            let metaString = metadata
                .map { "[\($0.key)=\($0.value)]" }
                .joined()
            let logMessage = "\(tagString)\(metaString) "
            + "\(actualMessage)" // Use the evaluated message
            
            os_log("%{public}@", log: self.osLog,
                   type: level.osLogType,
                   logMessage)
        }
    }
    
    /// Logs multiple messages if their level is allowed.
    ///
    /// - Parameters:
    ///   - messages: One or more ``Message`` instances to be logged.
    ///   - level: The severity level.
    ///   - tags: An array of `Tag` values for categorization.
    ///   - metadata: A dictionary of extra context.
    ///   - file: The file where the log is called
    ///           (default: `#file`).
    ///   - function: The function name
    ///               (default: `#function`).
    ///   - line: The line number (default: `#line`).
    public func log(
        _ messages: Message...,
        level: LogLevel,
        tags: [Tag] = [],
        metadata: [String: CustomStringConvertible] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Early exit if level is not allowed (check outside queue for efficiency)
        queue.sync { // Use queue.sync for reading allowedLevels safely
            guard allowedLevels.isEmpty || allowedLevels.contains(level) else {
                return
            }
            
            let tagString = tags.map { "[\($0.rawValue)]" }.joined()
            let metaString = metadata.map { "[\($0.key)=\($0.value)]" }.joined()
            // ------------------------------------
            
            for messageClosure in messages {
                let actualMessage = messageClosure() // Evaluate the closure
                let logMessage = "\(tagString)\(metaString) \(actualMessage)"
                
                // Log using os_log
                os_log(
                    "%{public}@",
                    log: self.osLog,
                    type: level.osLogType,
                    logMessage
                )
                
                // Speak the log if enabled (platform-specific implementation)
                if speakLogsEnabled {
                    #if os(macOS)
                    // macOS: Use Process to call 'say' command
                    // NOTE: Running this synchronously within the loop might cause delays
                    // if many messages are logged quickly. Consider background execution if needed.
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
                    // Base arguments
                    var args = [String]()
                    // Add voice if specified
                    if let voiceId = self.speechVoiceIdentifier {
                        args.append("-v")
                        args.append(voiceId)
                    }
                    // Add rate if specified (converting Float to WPM)
                    if let rate = self.speechRate {
                        let wpm = Int( min(350, max(50, 50 + (rate * 275))) ) // Map 0.0-1.0 -> 50-325 WPM, clamp
                        args.append("-r")
                        args.append("\(wpm)")
                    }
                    // Add message
                    args.append("\(level.rawValue): \(actualMessage)")
                    process.arguments = args
                    do {
                        try process.run()
                        process.waitUntilExit() // Waits here for speech to finish
                    } catch {
                        os_log("Failed to execute 'say' command: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
                    }
                    #elseif os(iOS) || os(tvOS)
                    // iOS/tvOS: Use AVSpeechSynthesizer
                    // AVSpeechSynthesizer handles queuing internally
                    let utterance = AVSpeechUtterance(string: "\(level.rawValue): \(actualMessage)")
                    // Set voice if specified
                    if let voiceId = self.speechVoiceIdentifier {
                        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
                    }
                    // Set rate if specified
                    if let rate = self.speechRate {
                        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate))
                    }
                    // Set pitch if specified
                    if let pitch = self.speechPitch {
                        utterance.pitchMultiplier = max(0.5, min(2.0, pitch))
                    }
                    self.speechSynthesizer.speak(utterance)
                    #endif
                }
            }
        }
    }
}
