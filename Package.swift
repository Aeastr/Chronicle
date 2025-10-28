// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Chronicle",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Chronicle",
            targets: ["Chronicle"]
        ),
        .library(
            name: "ChronicleConsole",
            targets: ["ChronicleConsole"]
        ),
        .library(
            name: "ChronicleSwiftLogBridge",
            targets: ["ChronicleSwiftLogBridge"]
        ),
        .library(
            name: "ChronicleExamples",
            targets: ["ChronicleExamples"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "Chronicle",
            dependencies: []
        ),
        .target(
            name: "ChronicleConsole",
            dependencies: [
                "Chronicle"
            ]
        ),
        .target(
            name: "ChronicleSwiftLogBridge",
            dependencies: [
                "Chronicle",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "ChronicleExamples",
            dependencies: [
                "Chronicle",
                "ChronicleConsole"
            ]
        )
    ]
)
