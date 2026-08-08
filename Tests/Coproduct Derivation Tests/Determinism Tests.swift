// Determinism Tests.swift

import CoproductDerivation
import DeclarationDerivationAnalysis
import DeclarationDerivationDiagnostics
import DeclarationDerivationModel
import DeclarationSwiftSyntaxAdapter
import Testing

extension Coproduct.Derivation.Model {
  @Suite struct Test {
    /// Positive control: deriving the fixture corpus twice yields
    /// byte-identical models, folds, prisms and provenance.
    @Test(
      arguments: [
        FixtureCorpus.zeroCaseEnumeration,
        FixtureCorpus.singleCaseEnumeration,
        FixtureCorpus.labelPreservingEnumeration,
      ]
    )
    func `deriving a fixture twice is byte-identical`(source: String) throws {
      let adapter = Declaration.SwiftSyntaxAdapter()
      let analyzer = Declaration.Derivation.Analyzer()
      let emitter = Coproduct.Derivation.Emitter(contract: .version1)
      let prismEmitter = Coproduct.Derivation.PrismEmitter()

      func derive() throws(Declaration.Derivation.Diagnostic)
        -> (Coproduct.Derivation.Model, [String], [String])
      {
        let intermediateRepresentation = try adapter.intermediateRepresentation(
          from: FixtureCorpus.declaration(source)
        )
        let analyzed = try analyzer.analyze(intermediateRepresentation)
        let model = try Coproduct.Derivation.Model(analyzed)
        return (
          model,
          emitter.memberDeclarations(for: model),
          prismEmitter.memberDeclarations(for: model)
        )
      }

      let first = try derive()
      let second = try derive()
      #expect(first.0 == second.0)
      #expect(first.1 == second.1)
      #expect(first.2 == second.2)
      #expect(
        first.1.joined(separator: "\n").utf8
          .elementsEqual(second.1.joined(separator: "\n").utf8)
      )
      #expect(
        first.2.joined(separator: "\n").utf8
          .elementsEqual(second.2.joined(separator: "\n").utf8)
      )
    }

    /// Negative control: a non-coproduct declaration fails with the same
    /// stable diagnostic on every run.
    @Test func `a structure yields the stable diagnostic twice`() throws {
      let adapter = Declaration.SwiftSyntaxAdapter()
      let intermediateRepresentation = try adapter.intermediateRepresentation(
        from: FixtureCorpus.declaration(FixtureCorpus.structureDeclaration)
      )

      func diagnostic() -> Declaration.Derivation.Diagnostic? {
        do throws(Declaration.Derivation.Diagnostic) {
          _ = try Coproduct.Derivation.Model(intermediateRepresentation)
          return nil
        } catch {
          return error
        }
      }

      let first = diagnostic()
      let second = diagnostic()
      #expect(first != nil)
      #expect(first == second)
      #expect(first?.code == .unsupportedDeclarationKind)
    }
  }
}
