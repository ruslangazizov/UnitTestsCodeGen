// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnitTestsCodeGen",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.34.1")
    ],
    targets: [
        .executableTarget(
            name: "UnitTestsCodeGen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SourceKittenFramework", package: "SourceKitten")
            ]
        ),
        .testTarget(
            name: "UnitTestsCodeGenTests",
            dependencies: ["UnitTestsCodeGen"]
        ),
    ]
)
