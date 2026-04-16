// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RequestResponse",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v13),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "RequestResponse",
            targets: ["RequestResponse"]
        ),
    ],
    targets: [
        .target(
            name: "RequestResponse"
        ),
        .testTarget(
            name: "RequestResponseTests",
            dependencies: ["RequestResponse"]
        ),
    ]
)
