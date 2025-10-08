// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "LogOutLoud",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "LogOutLoud",
            targets: ["LogOutLoud"]
        ),
        .library(
            name: "LogOutLoudConsole",
            targets: ["LogOutLoudConsole"]
        ),
        .library(
            name: "LogOutLoudExamples",
            targets: ["LogOutLoudExamples"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "LogOutLoud",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "LogOutLoudConsole",
            dependencies: [
                "LogOutLoud"
            ]
        ),
        .target(
            name: "LogOutLoudExamples",
            dependencies: [
                "LogOutLoud",
                "LogOutLoudConsole"
            ]
        )
    ]
)
