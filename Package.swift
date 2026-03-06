// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrivacyDisplayKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PrivacyDisplayKit",
            targets: ["PrivacyDisplayKit"]
        )
    ],
    targets: [
        .target(
            name: "PrivacyDisplayKit",
            dependencies: [],
            path: "Sources/PrivacyDisplayKit"
        ),
        .testTarget(
            name: "PrivacyDisplayKitTests",
            dependencies: ["PrivacyDisplayKit"],
            path: "Tests/PrivacyDisplayKitTests"
        )
    ]
)
