<div align="center">
  <img width="300" height="300" src="/assets/icon.png" alt="LogOutLoud Logo">
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

- A global, shared `Logger` singleton  
- Multiple named shared logger instances for packages/modules  
- Extensible, enum-style `Tag`s  
- Runtime filtering by `LogLevel`  
- Optional metadata dictionary for structured context  
- Zero overhead for disabled logs  


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
// Named and convenience loggers (both sync and async available)
// ---

// Synchronous usage (works anywhere)
// - Use this when thread safety is not a concern
// - Not recommended for concurrent access
let packageLogger = Logger.shared(for: "com.example.package")
packageLogger.setAllowedLevels([.debug, .info])
packageLogger.log("Log from package", level: .debug)

// Async usage (recommended for thread safety)
// - Use this when you need thread-safe access
// - Required for concurrent access
Task {
    let asyncLogger = await Logger.shared(for: "com.example.package")
    await asyncLogger.setAllowedLevels([.debug, .info])
    asyncLogger.log("Log from package", level: .debug)
}

// Convenience: Predefined shared loggers
// - Both sync and async versions available
let pkgLogger = Logger.package() // sync version
pkgLogger.log("Package log", level: .info)

let asyncPkgLogger = await Logger.package() // async version
await asyncPkgLogger.setAllowedLevels([.debug, .info])
asyncPkgLogger.log("Package log", level: .info)
```

> **Note:**
> - `Logger.shared` is always available synchronously and is suitable for most simple use cases.
> - Named/convenience loggers are available both synchronously and asynchronously.
> - Use the async versions (`await Logger.shared(for:)`) when you need thread-safe access or when working with concurrent code.
> - Use the synchronous versions (`Logger.shared(for:)`) when thread safety is not a concern or when you're not working with concurrent code.

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
  metadata: ["url": request.url, "userID": user.id]
)
```

---

## Use Cases

- **Development debugging** – verbose, tagged tracing  
- **Production filtering** – errors/faults only in release builds  
- **Subsystem categorization** – network, cache, UI, database  
- **Structured context** – attach user IDs, request IDs, timing info  
- **Performance-friendly** – delegates to `os_log`, Apple-optimised  

---

## Why LogOutLoud?

- **Less boilerplate** than raw `os_log` calls  
- **Centralised configuration** for filtering and formatting  
- **Swift-friendly**, type-safe tags instead of string literals  
- **Optional metadata** without pulling in heavy frameworks  
- **Zero-overhead** when logs are filtered out  

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
