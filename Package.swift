// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacTapa",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MacTapa",
            path: "Sources/MacTapa",
            resources: [
                .copy("../../Resources/Sounds")
            ]
        )
    ]
)
