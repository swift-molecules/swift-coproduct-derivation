// swift-tools-version: 6.3.3

import CompilerPluginSupport
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
        // MARK: - Coproduct derivation core (model, fold emitter, prism emitter)
        .library(
            name: "Coproduct Derivation",
            targets: ["CoproductDerivation"]
        ),
        .library(
            name: "Coproduct Derivation Macros",
            targets: ["CoproductDerivationMacros"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-declaration-derivation.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    ],
    targets: [
        // MARK: - Coproduct derivation core (syntax-free, Foundation-free)
        // TX-D2 owns the semantic content: the nominal coproduct model over
        // the shared declaration IR, the exhaustive fold emitter and the
        // optional prism emitter.
        .target(
            name: "CoproductDerivation",
            dependencies: [
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
            ]
        ),
        // MARK: - Attached-macro front (@Coproduct; build-time only, excluded from Embedded)
        .macro(
            name: "CoproductDerivationMacros",
            dependencies: [
                "CoproductDerivation",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Analysis", package: "swift-declaration-derivation"),
                .product(name: "Declaration SwiftSyntax Adapter", package: "swift-declaration-derivation"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "Coproduct Derivation Tests",
            dependencies: [
                "CoproductDerivation",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Analysis", package: "swift-declaration-derivation"),
                .product(name: "Declaration SwiftSyntax Adapter", package: "swift-declaration-derivation"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "Coproduct Derivation Macros Tests",
            dependencies: [
                "CoproductDerivationMacros",
                "CoproductDerivation",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
