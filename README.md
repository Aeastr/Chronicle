<div align="center">
  <img width="270" height="270" src="/assets/icon.png" alt="LogOutLoud Logo">
  <h1><b>LogOutLoud</b></h1>
  <p>
    A lightweight Swift logging package that wraps Apple’s Unified Logging
    (`os_log`)
    <br>
    <i>Compatible with iOS 13.0, macOS 10.15, tvOS 13, watchOS 6 and later</i>
  </p>
</div>

<div align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.0%2B-orange.svg" alt="Swift Version">
  </a>
  <a href="https://developer.apple.com/ios/">
    <img src="https://img.shields.io/badge/iOS-13%2B-blue.svg" alt="iOS 13+">
  </a>
  <a href="https://developer.apple.com/macos/">
    <img src="https://img.shields.io/badge/macOS-10.15%2B-lightgrey.svg" alt="macOS 10.15+">
  </a>
  <a href="https://developer.apple.com/tvos/">
    <img src="https://img.shields.io/badge/tvOS-13%2B-lightgrey.svg" alt="tvOS 13+">
  </a>
  <a href="https://developer.apple.com/watchos/">
    <img src="https://img.shields.io/badge/watchOS-6%2B-lightgrey.svg" alt="watchOS 6+">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  </a>
</div>


## Features

- Adaptive backend: Apple’s modern `os.Logger` on supported OS versions, seamless `os_log` fallback otherwise  
- A global, shared `Logger` singleton plus multiple keyed shared instances for packages/modules  
- Extensible, enum-style `Tag`s and JSON-like structured metadata via `LogMetadataValue`  
- Runtime filtering by `LogLevel`, async logging helper, and zero-overhead disabled logs  
- Optional in-app console with SwiftUI view, environment modifier, and composable store  
- Signpost convenience APIs for performance tracing  
- Optional SwiftLog integration (`LoggingSystem.bootstrapLogOutLoud`)  


---

## Multiple Shared Logger Instances

By default, `Logger.shared` is a singleton used across your app and any packages that import LogOutLoud. 

**However, you can now create and access multiple shared logger instances, each with their own configuration, using a registry pattern:**

### Why?
- This allows packages, modules, or features to have separate logging controls.
- For example, you can enable verbose logging for your network layer, but only show errors for a third-party package.
- Each logger instance can have its own allowed levels, subsystem, and filtering.

### Usage

```swift
// ---
// Default global logger (synchronous, works anywhere)
Logger.shared.log("App log", level: .info)

// ---
// Named loggers for packages, modules, or features (synchronous, concurrency-safe)
let packageLogger = Logger.shared(for: "com.example.package")
packageLogger.setAllowedLevels([.debug, .info])
packageLogger.log("Log from package", level: .debug)

let networkLogger = Logger.shared(for: "com.example.network")
networkLogger.setAllowedLevels([.error, .fault])
networkLogger.log("Network error", level: .error)
```

> **Note:**
> - All logger APIs are concurrency-safe for Swift 6.
> - `Logger.shared(for:)` uses an internal thread-safe registry.
> - Use `logAsync` when you want to await expensive message builders without blocking callers.

**This pattern helps you keep logs organized and makes it easy to control logging granularity for different parts of your app or dependencies.**

---

## Installation

You can add `LogOutLoud` to your project using Swift Package Manager.

1.  In Xcode, select **File** > **Add Packages...**
2.  Enter the repository URL: `https://github.com/aeastr/LogOutLoud.git`
3.  Choose the `main` branch or the latest version tag.
4.  Add the `LogOutLoud` library to your app target.

Alternatively, add it to your `Package.swift` dependencies:

```swift
dependencies: [
.package(url: "https://github.com/aeastr/LogOutLoud.git", from: "1.0.0") 
]
```

---


## API Overview

### Tag

```swift
public struct Tag: RawRepresentable, Hashable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String)
    public init(_ rawValue: String)
}
```

### LogLevel

```swift
public enum LogLevel: Int, CaseIterable, Comparable {
    case debug, info, notice, warning, error, fault
    public var osLogType: OSLogType
}
```

### LogMetadataValue

```swift
public enum LogMetadataValue: Sendable, CustomStringConvertible {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case array([LogMetadataValue])
    case dictionary([String: LogMetadataValue])
    case null
}
```

Use `LogMetadataValue` (or its literal conformances) to build structured metadata payloads that render as JSON-like strings.

### Logger

```swift
public final class Logger {
    public static let shared: Logger
    public var subsystem: String
    public func setAllowedLevels(_ levels: Set<LogLevel>)
    public func log(
        _ message: @autoclosure () -> String,
        level: LogLevel,
        tags: [Tag],
        metadata: [String: CustomStringConvertible],
        file: String, function: String, line: Int
    )
    public func log(
        _ messages: () -> String...,
        level: LogLevel,
        tags: [Tag],
        metadata: [String: CustomStringConvertible],
        file: String, function: String, line: Int
    )
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @discardableResult
    public func logAsync(
        priority: TaskPriority?,
        level: LogLevel,
        tags: [Tag],
        metadata: [String: CustomStringConvertible],
        file: String, function: String, line: Int,
        _ message: @escaping @Sendable () async -> String
    ) -> Task<Void, Never>
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func beginSignpost(...)
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func endSignpost(...)
    @available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *)
    public func eventSignpost(...)
}
```

---

## Quick Start

### 1. Import

```swift
import LogOutLoud
```

### 2. Define Your Tags

```swift
extension Tag {
  static let cache   = Tag("Cache")
  static let network = Tag("Network")
  static let ui      = Tag("UI")
}
```

### 3. Configure the Logger

Call once at app launch (e.g. in `AppDelegate` or your `@main`):

```swift
// Set the OSLog subsystem (defaults to bundle ID)
Logger.shared.subsystem =
  Bundle.main.bundleIdentifier ?? "com.myapp"

// DEBUG builds: all levels; RELEASE builds: errors only
#if DEBUG
  Logger.shared.setAllowedLevels(
    Set(LogLevel.allCases)
  )
#else
  Logger.shared.setAllowedLevels([.error, .fault])
#endif
```

### 4. Emit Logs

Anywhere in your code:

```swift
Logger.shared.log(
  "Loaded from disk",
  level: .info,
  tags: [.cache]
)

Logger.shared.log(
  "Request failed",
  level: .error,
  tags: [.network],
  metadata: [
    "url": request.url,
    "userID": user.id,
    "retry": false,
    "metrics": ["duration_ms": 128]
  ]
)
```

### 5. Optional Async Logging

```swift
await Logger.shared.logAsync(level: .debug, tags: [.network]) {
  try await DetailedRequestDebugger.makeSummary(for: transaction)
}
```

---

## Use Cases

- **Development debugging** – verbose, tagged tracing  
- **Production filtering** – errors/faults only in release builds  
- **Subsystem categorization** – network, cache, UI, database  
- **Structured context** – attach user IDs, request IDs, timing info  
- **Performance-friendly** – delegates to Unified Logging backends  
- **Signpost timelines** – wrap begin/end/event spans without extra boilerplate  
- **SwiftLog compatible** – drop into server-side or cross-platform logging stacks  

---

## Structured Metadata

Metadata dictionaries are coerced into `LogMetadataValue` behind the scenes, giving you JSON-like output without heavy dependencies:

```swift
Logger.shared.log(
  "Cache miss",
  level: .notice,
  tags: [.cache],
  metadata: [
    "key": "user_42",
    "reason": "Expired",
    "context": [
      "policy": "LRU",
      "lastHit": 1_714_882_233,
      "counts": [1, 3, 5]
    ]
  ]
)
```

Output resembles:

```
[Cache] Cache miss | {"_source":{"file":"Cache.swift","function":"fetch(_:)","line":42},"_subsystem":"com.myapp","_tags":["Cache"],"context":{"counts":[1,3,5],"lastHit":1714882233,"policy":"LRU"},"key":"user_42","reason":"Expired"}
```

---

## Signposts

When `os.signpost` is available you can trace performance-critical paths using the same metadata helpers:

```swift
let id = Logger.shared.beginSignpost("Image Decode", tags: [.ui])
defer { Logger.shared.endSignpost("Image Decode", id: id) }
```

Use `eventSignpost` for single-point events.

---

## SwiftLog Integration

Prefer the `swift-log` API surface? Bootstrap once and use `Logging.Logger` everywhere:

```swift
import Logging
import LogOutLoud

LoggingSystem.bootstrapLogOutLoud(defaultLogLevel: .info)

let logger = Logger(label: "com.myapp.feature")
logger.notice("Task queued", metadata: ["id": .string(task.id)])
```

Under the hood LogOutLoud bridges the message, metadata, and level mappings back to Unified Logging.

---

## In-App Log Console

Need an on-device console for QA or support builds? LogOutLoud can mirror every emitted entry into a live buffer that powers a SwiftUI view.

### Enable the console

Opt-in so there is zero overhead when you do not need UI logging:

```swift
// Typically in your App or setup code
let consoleStore = Logger.shared.enableConsole(maxEntries: 1_000)
```

### Wire it into SwiftUI

Use the provided environment modifier and drop-in view:

```swift
struct RootView: View {
    @State private var showConsole = false

    var body: some View {
        Content()
            .logConsole(enabled: true) // installs the live sink lazily
            .toolbar {
                Button("Console") { showConsole = true }
            }
            .sheet(isPresented: $showConsole) {
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
                    LogConsolePanel() // uses the environment store by default
                } else {
                    Text("Console available on iOS 16+/macOS 13+/tvOS 16+.")
                }
            }
    }
}
```

Prefer to build your own UI? Inject the `LogConsoleStore` manually and read its `entries` array, or register a custom `LogEventSink` for alternative destinations.

> The provided SwiftUI console components target iOS 16.0, macOS 13.0, and tvOS 16.0 or newer.

---

## Why LogOutLoud?

- **Less boilerplate** than raw `os_log` calls  
- **Centralised configuration** for filtering and formatting  
- **Swift-friendly**, type-safe tags instead of string literals  
- **Structured metadata** without pulling in heavy frameworks  
- **Zero-overhead** when logs are filtered out  
- **Tools ready** with async helpers, signposts, and SwiftLog adapter  

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE.md) for details.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Before you begin, take a moment to review the [Contributing Guide](CONTRIBUTING.md) for details on issue reporting, coding standards, and the PR process.

## Support

If you like this project, please consider giving it a ⭐️

---

## Where to find me:  
- here, obviously.  
- [Twitter](https://x.com/AetherAurelia)  
- [Threads](https://www.threads.net/@aetheraurelia)  
- [Bluesky](https://bsky.app/profile/aethers.world)  
- [LinkedIn](https://www.linkedin.com/in/willjones24)

---

<p align="center">Built with 🍏📝🔊 by Aether</p>
