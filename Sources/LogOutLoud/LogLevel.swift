//
//  LogLevel.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import os
import SwiftUI

/// The severity level of a log message.
///
/// Levels are comparable so you can filter messages by
/// severity.
///
/// ```swift
/// if level >= .error { … }
/// ```
public enum LogLevel: Int, CaseIterable, Comparable {
    /// Debug-level messages. Enabled in debug builds.
    case debug = 0
    /// Informational messages.
    case info
    /// Normal, significant events (maps to `.default`).
    case notice
    /// Warning conditions (maps to `.default`).
    case warning
    /// Error conditions.
    case error
    /// Severe failure conditions.
    case fault
    
    /// Maps our `LogLevel` to an `OSLogType`.
    public var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice, .warning:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
    
    /// Conformance for sorting and filtering.
    public static func < (lhs: LogLevel,
                          rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension LogLevel {
    /// Maps our ``LogLevel`` to Apple's modern `os.Logger.Level` enumeration.
    var osLoggerLevel: os.Logger.Level {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}
