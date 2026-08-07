// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-coproduct-derivation",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        // MARK: - Namespace (per [MOD-017])
        .library(
            name: "Coproduct Derivation",
            targets: ["Coproduct Derivation"]
        ),
    ],
    targets: [
        // MARK: - Namespace (per [MOD-017])
        // TX-D0 bootstrap scaffold; the D1 transaction owns the semantic
        // content (the coproduct derivation with its attached-macro front).
        .target(
            name: "Coproduct Derivation",
            dependencies: []
        ),
    ]
)
