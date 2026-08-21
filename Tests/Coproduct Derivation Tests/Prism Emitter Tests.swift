import Coproduct_Derivation_Core
import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import Testing

extension Coproduct.Derivation.PrismEmitter {
    @Suite struct Test {
        let emitter = Coproduct.Derivation.PrismEmitter()

        @Test func `payload-free case derives the Void prism`() throws {
            let model = try Coproduct.Derivation.Model(
                Declaration.IR(node: FixtureCorpus.payloadModelNode)
            )
            let prisms = emitter.memberDeclarations(for: model)
            let start = try #require(prisms.first)
            #expect(start.contains("public var startPrism: Void? {"))
            #expect(start.contains("guard case .start = self else {"))
            #expect(start.contains("return ()"))
        }

        @Test func `payload case derives the payload prism`() throws {
            let model = try Coproduct.Derivation.Model(
                Declaration.IR(node: FixtureCorpus.payloadModelNode)
            )
            let prisms = emitter.memberDeclarations(for: model)
            let retry = try #require(prisms.last)
            #expect(retry.contains("public var retryPrism: (Int)? {"))
            #expect(retry.contains("guard case .retry(let value) = self else {"))
            #expect(retry.contains("return value"))
        }

        @Test func `zero-case enumeration derives no prisms`() throws {
            let node = Declaration.Node(
                kind: .enumeration,
                name: Declaration.Node.Name("Impossible"),
                members: []
            )
            let model = try Coproduct.Derivation.Model(Declaration.IR(node: node))
            #expect(emitter.memberDeclarations(for: model).isEmpty)
        }
    }
}
