//
//  LogMetadata.swift
//  LogOutLoud
//
//  Created by Codex on 24/04/2025.
//

import CoreGraphics
import Foundation

/// A structured metadata value that can encode primitive scalars, arrays, or nested dictionaries.
public enum LogMetadataValue: Sendable, CustomStringConvertible {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case array([LogMetadataValue])
    case dictionary([String: LogMetadataValue])
    case null

    public var description: String {
        switch self {
        case .string(let value):
            return "\"\(Self.escape(value))\""
        case .integer(let value):
            return String(value)
        case .double(let value):
            return value.cleanDescription
        case .bool(let value):
            return value ? "true" : "false"
        case .array(let values):
            let contents = values.map { $0.description }.joined(separator: ",")
            return "[\(contents)]"
        case .dictionary(let dictionary):
            let contents = dictionary
                .sorted { $0.key < $1.key }
                .map { key, value in
                    "\"\(Self.escape(key))\":\(value.description)"
                }
                .joined(separator: ",")
            return "{\(contents)}"
        case .null:
            return "null"
        }
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

public typealias LogMetadata = [String: LogMetadataValue]

// MARK: - Literal conformances

extension LogMetadataValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension LogMetadataValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension LogMetadataValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension LogMetadataValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .integer(value)
    }
}

extension LogMetadataValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension LogMetadataValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: LogMetadataValue...) {
        self = .array(elements)
    }
}

extension LogMetadataValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, LogMetadataValue)...) {
        var dictionary: [String: LogMetadataValue] = [:]
        dictionary.reserveCapacity(elements.count)
        for (key, value) in elements {
            dictionary[key] = value
        }
        self = .dictionary(dictionary)
    }
}

// MARK: - Helpers

extension LogMetadataValue {
    /// Normalises arbitrary values into ``LogMetadataValue``.
    ///
    /// This is primarily useful when working with `[String: CustomStringConvertible]` metadata inputs.
    static func fromAny(_ value: Any) -> LogMetadataValue {
        switch value {
        case let metadata as LogMetadataValue:
            return metadata
        case let value as LogMetadata:
            return .dictionary(value)
        case let value as [String: Any]:
            let nested = value.reduce(into: LogMetadata()) { result, element in
                result[element.key] = LogMetadataValue.fromAny(element.value)
            }
            return .dictionary(nested)
        case let value as [Any]:
            let nested = value.map { LogMetadataValue.fromAny($0) }
            return .array(nested)
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .integer(value)
        case let value as Int8:
            return .integer(Int(value))
        case let value as Int16:
            return .integer(Int(value))
        case let value as Int32:
            return .integer(Int(value))
        case let value as Int64:
            return .integer(Int(value))
        case let value as UInt:
            return .integer(Int(value))
        case let value as UInt8:
            return .integer(Int(value))
        case let value as UInt16:
            return .integer(Int(value))
        case let value as UInt32:
            return .integer(Int(value))
        case let value as UInt64:
            return .integer(Int(value))
        case let value as Double:
            return .double(value)
        case let value as Float:
            return .double(Double(value))
        case let value as CGFloat:
            return .double(Double(value))
        case let value as NSNumber:
            // Distinguish booleans from numeric representations.
            if CFBooleanGetTypeID() == CFGetTypeID(value) {
                return .bool(value.boolValue)
            }
            if CFNumberIsFloatType(value) {
                return .double(value.doubleValue)
            }
            return .integer(value.intValue)
        case let value as String:
            return .string(value)
        case let value as CustomStringConvertible:
            return .string(value.description)
        default:
            return .string(String(describing: value))
        }
    }
}

private extension Double {
    /// Trims trailing zeros while preserving decimal output for integers.
    var cleanDescription: String {
        var string = String(self)
        if string.contains(".") {
            while string.last == "0" {
                string.removeLast()
            }
            if string.last == "." {
                string.removeLast()
            }
        }
        return string
    }
}
