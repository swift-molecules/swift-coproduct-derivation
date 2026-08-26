// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-coproduct-derivation",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(
            name: "Coproduct Derivation",
            targets: ["Coproduct Derivation Core", "Coproduct Derivation"]
        ),
        .library(
            name: "Coproduct Derivation Macros",
            targets: ["CoproductDerivationMacros"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-declaration-derivation.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    ],
    targets: [

        .target(
            name: "Coproduct Derivation",
            dependencies: [
                "Coproduct Derivation Core",
                "CoproductDerivationMacros",
            ]
        ),

        .target(
            name: "Coproduct Derivation Core",
            dependencies: [
                .product(
                    name: "Declaration Derivation Model",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Diagnostics",
                    package: "swift-declaration-derivation"
                ),
            ]
        ),

        .macro(
            name: "CoproductDerivationMacros",
            dependencies: [
                "Coproduct Derivation Core",
                .product(
                    name: "Declaration Derivation Model",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Diagnostics",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Analysis",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration SwiftSyntax Adapter",
                    package: "swift-declaration-derivation"
                ),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        .testTarget(
            name: "Coproduct Derivation Consumer Tests",
            dependencies: [
                "Coproduct Derivation Core",
                "Coproduct Derivation",
            ]
        ),
        .testTarget(
            name: "Coproduct Derivation Tests",
            dependencies: [
                "Coproduct Derivation Core",
                .product(
                    name: "Declaration Derivation Model",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Diagnostics",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Analysis",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration SwiftSyntax Adapter",
                    package: "swift-declaration-derivation"
                ),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "Coproduct Derivation Macros Tests",
            dependencies: [
                "CoproductDerivationMacros",
                "Coproduct Derivation Core",
                .product(
                    name: "Declaration Derivation Model",
                    package: "swift-declaration-derivation"
                ),
                .product(
                    name: "Declaration Derivation Diagnostics",
                    package: "swift-declaration-derivation"
                ),
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
