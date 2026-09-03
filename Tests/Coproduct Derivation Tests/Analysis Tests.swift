import Coproduct_Derivation_Core
import SwiftParser
import SwiftSyntax
import Testing

@Test
func `analysis preserves payload syntax and finds semantic generic references`() throws {
    let source = Parser.parse(
        source: """
        private enum Choice<Value> {
            case value(payload: Value)
            case retained([Value])
            case qualified(Qualified.Value)
            case labeled(code: Int, note: String)
        }
        """
    )
    let declaration = try #require(
        source.statements.first?.item.as(EnumDeclSyntax.self)
    )
    let analysis = Analysis(declaration)
    let parameter = try #require(analysis.genericParameter)

    #expect(analysis.access?.name.tokenKind == .keyword(.fileprivate))
    #expect(analysis.cases.map(\.name.text) == [
        "value", "retained", "qualified", "labeled"
    ])
    #expect(analysis.cases[0].isDirectReference(to: parameter))
    #expect(analysis.cases[1].references(parameter))
    #expect(!analysis.cases[2].references(parameter))
    #expect(
        analysis.cases[3].payload.trimmedDescription
            == "(code: Int, note: String)"
    )
}
