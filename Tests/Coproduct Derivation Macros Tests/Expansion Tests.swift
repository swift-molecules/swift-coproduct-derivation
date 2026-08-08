// Expansion Tests.swift

import CoproductDerivation
import DeclarationDerivationDiagnostics
import DeclarationDerivationModel
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import CoproductDerivationMacros

// MARK: - Macro registry

private let coproductMacros: [String: MacroSpec] = [
  "Coproduct": MacroSpec(type: Coproduct.Macro.self)
]

// MARK: - Swift Testing adapter

/// Bridges `SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion`'s
/// framework-agnostic `failureHandler` callback to Swift Testing's
/// `Issue.record(...)`.
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

// MARK: - Expansion fixtures (the expected sources are the API snapshot of the expanded interface)

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
          "contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-coproduct-derivation@main"
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
          "contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-coproduct-derivation@main"
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
          "contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-coproduct-derivation@main"
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

private let structureFixture = """
  @Coproduct
  struct Point {
      let x: Int
  }
  """

extension Coproduct.Macro {
  @Suite struct Test {
    /// Self-firing control: the fixture corpus expands twice with identical
    /// expansions; the expected sources are the API snapshot.
    @Test func `fixture corpus expands identically twice`() {
      for _ in 1...2 {
        expectMacroExpansion(enumerationFixture, expandedSource: enumerationFixtureExpansion)
        expectMacroExpansion(zeroCaseFixture, expandedSource: zeroCaseFixtureExpansion)
        expectMacroExpansion(prismFixture, expandedSource: prismFixtureExpansion)
      }
    }

    /// Near-miss control: without `prisms: true` the expansion contains no
    /// prism member, and the handwritten declaration body is untouched.
    @Test func `prism emission is opt-in`() {
      expectMacroExpansion(enumerationFixture, expandedSource: enumerationFixtureExpansion)
    }

    /// Negative control: a non-coproduct declaration expands to nothing and
    /// emits the stable diagnostic.
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
