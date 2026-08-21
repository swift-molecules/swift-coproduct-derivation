import Coproduct_Derivation_Core
import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
import Testing

extension Coproduct.Derivation.Emitter {
    @Suite struct Test {
        let emitter = Coproduct.Derivation.Emitter(contract: .version1)
        let adapter = Declaration.SwiftSyntaxAdapter()

        private func model(
            _ source: String
        ) throws(Declaration.Derivation.Diagnostic) -> Coproduct.Derivation.Model {
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(source)
            )
            let analyzed = try Declaration.Derivation.Analyzer().analyze(intermediateRepresentation)
            return try Coproduct.Derivation.Model(analyzed)
        }

        @Test func `zero-case enumeration derives the closed fold`() throws {
            let members = emitter.memberDeclarations(
                for: try model(FixtureCorpus.zeroCaseEnumeration)
            )
            let fold = try #require(members.first)
            #expect(fold.contains("public func fold<Result>() -> Result {"))
            #expect(fold.contains("switch self {"))
        }

        @Test func `single-case enumeration derives the one-arm fold`() throws {
            let members = emitter.memberDeclarations(
                for: try model(FixtureCorpus.singleCaseEnumeration)
            )
            let fold = try #require(members.first)
            #expect(fold.contains("only: () -> Result"))
            #expect(fold.contains("case .only:"))
            #expect(fold.contains("only()"))
        }

        @Test func `fold preserves case order and is exhaustive`() throws {
            let members = emitter.memberDeclarations(
                for: try model(FixtureCorpus.labelPreservingEnumeration)
            )
            let fold = try #require(members.first)
            let startPosition = try #require(fold.firstRange(of: "start: () -> Result"))
            let stopPosition = try #require(fold.firstRange(of: "stop: () -> Result"))
            let retryPosition = try #require(fold.firstRange(of: "retry: () -> Result"))
            #expect(startPosition.lowerBound < stopPosition.lowerBound)
            #expect(stopPosition.lowerBound < retryPosition.lowerBound)
            #expect(fold.contains("case .retry:"))
        }

        @Test func `payload case folds with its payload`() throws {
            let model = try Coproduct.Derivation.Model(
                Declaration.IR(node: FixtureCorpus.payloadModelNode)
            )
            let members = emitter.memberDeclarations(for: model)
            let fold = members[0]
            #expect(fold.contains("retry: (Int) -> Result"))
            #expect(fold.contains("case .retry(let value):"))
            #expect(fold.contains("retry(value)"))
        }

        @Test func `model preserves payload label and default spellings`() throws {
            let model = try Coproduct.Derivation.Model(
                Declaration.IR(node: FixtureCorpus.payloadModelNode)
            )
            let retry = try #require(model.cases.last)
            #expect(retry.payloadLabel == Declaration.Node.Member.Label("count"))
            #expect(retry.payloadDefaultValue == Declaration.Node.Member.DefaultValue("1"))
        }

        @Test func `every expansion carries the contract provenance`() throws {
            let members = emitter.memberDeclarations(
                for: try model(FixtureCorpus.singleCaseEnumeration)
            )
            let provenance = try #require(members.last)
            #expect(provenance.contains(Coproduct.GenerationContract.version1.provenance))
            #expect(
                Coproduct.GenerationContract.version1.provenance
                    == "contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-coproduct-derivation@main"
            )
        }

        @Test func `near miss - handwritten file names stay outside the contract`() {
            let contract = Coproduct.GenerationContract.version1
            #expect(contract.isGenerated(fileName: "Command+CoproductDerivation.generated.swift"))
            #expect(!contract.isGenerated(fileName: "Command.swift"))
            #expect(!contract.isGenerated(fileName: "Command+Handwritten.swift"))
            #expect(
                !contract.isGenerated(fileName: "Command+DeclarationDerivation.generated.swift")
            )
        }

        @Test func `a structure is rejected with the stable diagnostic`() throws {
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.structureDeclaration)
            )
            do throws(Declaration.Derivation.Diagnostic) {
                _ = try Coproduct.Derivation.Model(intermediateRepresentation)
                Issue.record("expected an unsupported-declaration-kind diagnostic")
            } catch {
                #expect(error.code == .unsupportedDeclarationKind)
                #expect(
                    error.description
                        == "declaration.derivation.unsupported-declaration-kind [Point]: coproduct derivation covers enumerations only"
                )
            }
        }

        @Test func `duplicate case names are ambiguous ownership`() throws {
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.ambiguousEnumeration)
            )
            do throws(Declaration.Derivation.Diagnostic) {
                _ = try Declaration.Derivation.Analyzer().analyze(intermediateRepresentation)
                Issue.record("expected an ambiguous-ownership diagnostic")
            } catch {
                #expect(error.code == .ambiguousOwnership)
            }
        }
    }
}
