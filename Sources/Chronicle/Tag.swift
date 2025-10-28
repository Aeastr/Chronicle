//
//  Tag.swift
//  LogOutLoud
//
//  Created by Aether on 24/04/2025.
//

import Foundation

/// A lightweight, extensible tag for log messages.
///
/// You can define your own tags via extensions:
///
/// ```swift
/// extension Tag {
///     static let cache   = Tag("Cache")
///     static let network = Tag("Network")
/// }
/// ```
///
/// - Note: Conforms to `RawRepresentable`. You can create
///   a tag with `Tag(rawValue:)`, or use the convenience
///   initializer `Tag("Name")`.
public struct Tag: RawRepresentable, Hashable, CustomStringConvertible, Sendable {
    /// The underlying raw string value of the tag.
    public let rawValue: String
    
    /// Creates a new `Tag` from a raw string.
    ///
    /// - Parameter rawValue: The string to use as the tag.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Convenience initializer to create a `Tag` without
    /// using the `rawValue:` label.
    ///
    /// - Parameter rawValue: The string to use as the tag.
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    /// A textual representation of the tag.
    public var description: String {
        rawValue
    }
}
