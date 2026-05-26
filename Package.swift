// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Gunttodo",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Gunttodo", targets: ["Gunttodo"])
    ],
    targets: [
        .executableTarget(
            name: "Gunttodo",
            path: "Sources/Gunttodo"
        )
    ]
)
