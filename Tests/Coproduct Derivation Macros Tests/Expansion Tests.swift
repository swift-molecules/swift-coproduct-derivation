import Coproduct_Derivation_Core
import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import CoproductDerivationMacros

private let coproductMacros: [String: MacroSpec] = [
    "Coproduct": MacroSpec(type: Coproduct.Macro.self)
]

private func expectMacroExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: coproductMacros,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: failure.location.fileID.description,
                    filePath: failure.location.filePath.description,
                    line: Int(failure.location.line),
                    column: Int(failure.location.column)
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

private let enumerationFixture = """
    @Coproduct
    enum Direction {
        case north
        case south
    }
    """

private let enumerationFixtureExpansion = """
    enum Direction {
        case north
        case south

        public func fold<Result>(
            north: () -> Result,
            south: () -> Result
        ) -> Result {
            switch self {
            case .north:
                north()
            case .south:
                south()
            }
        }

        public static var coproductDerivationProvenance: String {
            "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"
        }
    }
    """

private let zeroCaseFixture = """
    @Coproduct
    enum Impossible {
    }
    """

private let zeroCaseFixtureExpansion = """
    enum Impossible {

        public func fold<Result>() -> Result {
            switch self {
            }
        }

        public static var coproductDerivationProvenance: String {
            "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"
        }
    }
    """

private let prismFixture = """
    @Coproduct(prisms: true)
    enum Toggle {
        case on
        case off
    }
    """

private let prismFixtureExpansion = """
    enum Toggle {
        case on
        case off

        public func fold<Result>(
            on: () -> Result,
            off: () -> Result
        ) -> Result {
            switch self {
            case .on:
                on()
            case .off:
                off()
            }
        }

        public static var coproductDerivationProvenance: String {
            "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"
        }

        public var onPrism: Void? {
            guard case .on = self else {
                return nil
            }
            return ()
        }

        public var offPrism: Void? {
            guard case .off = self else {
                return nil
            }
            return ()
        }
    }
    """

private let payloadFixture = """
    @Coproduct(prisms: true)
    enum Request {
        case failed(String)
    }
    """

private let payloadFixtureExpansion = """
    enum Request {
        case failed(String)

        public func fold<Result>(
            failed: (String) -> Result
        ) -> Result {
            switch self {
            case .failed(let value):
                failed(value)
            }
        }

        public static var coproductDerivationProvenance: String {
            "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"
        }

        public var failedPrism: (String)? {
            guard case .failed(let value) = self else {
                return nil
            }
            return value
        }
    }
    """

private let functionPayloadFixture = """
    @Coproduct(prisms: true)
    enum Callback {
        case callback(@Sendable () -> Void)
        case idle
    }
    """

private let functionPayloadFixtureExpansion = """
    enum Callback {
        case callback(@Sendable () -> Void)
        case idle

        public func fold<Result>(
            callback: (@Sendable () -> Void) -> Result,
            idle: () -> Result
        ) -> Result {
            switch self {
            case .callback(let value):
                callback(value)
            case .idle:
                idle()
            }
        }

        public static var coproductDerivationProvenance: String {
            "contract-revision=1;ir-schema=v1;package-version-pin=swift-molecules/swift-coproduct-derivation@main"
        }

        public var callbackPrism: (@Sendable () -> Void)? {
            guard case .callback(let value) = self else {
                return nil
            }
            return value
        }

        public var idlePrism: Void? {
            guard case .idle = self else {
                return nil
            }
            return ()
        }
    }
    """

private let structureFixture = """
    @Coproduct
    struct Point {
        let x: Int
    }
    """

extension Coproduct.Macro {
    @Suite struct Test {

        @Test func `fixture corpus expands identically twice`() {
            for _ in 1...2 {
                expectMacroExpansion(
                    enumerationFixture,
                    expandedSource: enumerationFixtureExpansion
                )
                expectMacroExpansion(zeroCaseFixture, expandedSource: zeroCaseFixtureExpansion)
                expectMacroExpansion(prismFixture, expandedSource: prismFixtureExpansion)
                expectMacroExpansion(payloadFixture, expandedSource: payloadFixtureExpansion)
                expectMacroExpansion(
                    functionPayloadFixture,
                    expandedSource: functionPayloadFixtureExpansion
                )
            }
        }

        @Test func `associated value is bound by fold and prism expansions`() {
            expectMacroExpansion(payloadFixture, expandedSource: payloadFixtureExpansion)
        }

        @Test func `function payload prism groups the complete payload type`() {
            expectMacroExpansion(
                functionPayloadFixture,
                expandedSource: functionPayloadFixtureExpansion
            )
        }

        @Test func `prism emission is opt-in`() {
            expectMacroExpansion(enumerationFixture, expandedSource: enumerationFixtureExpansion)
        }

        @Test func `a structure yields the stable diagnostic`() {
            expectMacroExpansion(
                structureFixture,
                expandedSource: """
                    struct Point {
                        let x: Int
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "declaration.derivation.unsupported-declaration-kind [Point]: coproduct derivation covers enumerations only",
                        line: 1,
                        column: 1
                    )
                ]
            )
        }
    }
}
