//
//  LogOutputOptions.swift
//  LogOutLoud
//
//  Created by Codex on 10/05/2025.
//

import Foundation

/// Controls how `Logger` renders metadata when forwarding to Unified Logging or stdout.
public struct LogOutputOptions: Sendable {
    public enum MetadataFormat: Sendable {
        case pretty
        case json
    }

    public enum MetadataKeyPolicy: Sendable {
        case all
        case include(Set<String>)
        case exclude(Set<String>)

        func allows(_ key: String) -> Bool {
            switch self {
            case .all:
                return true
            case .include(let keys):
                return keys.contains(key)
            case .exclude(let keys):
                return !keys.contains(key)
            }
        }
    }

    public var showMetadata: Bool
    public var metadataFormat: MetadataFormat
    public var metadataKeyPolicy: MetadataKeyPolicy
    public var showSubsystem: Bool
    public var showSource: Bool

    public init(
        showMetadata: Bool = true,
        metadataFormat: MetadataFormat = .pretty,
        metadataKeyPolicy: MetadataKeyPolicy = .exclude(["_tags"]),
        showSubsystem: Bool = true,
        showSource: Bool = true
    ) {
        self.showMetadata = showMetadata
        self.metadataFormat = metadataFormat
        self.metadataKeyPolicy = metadataKeyPolicy
        self.showSubsystem = showSubsystem
        self.showSource = showSource
    }

    public static let `default` = LogOutputOptions()
}
