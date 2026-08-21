import Declaration_Derivation_Model
import SwiftParser
import SwiftSyntax

enum FixtureCorpus {
}

extension FixtureCorpus {

    static let zeroCaseEnumeration = "enum Impossible {}"

    static let singleCaseEnumeration = """
        enum Unit {
            case only
        }
        """

    static let labelPreservingEnumeration = """
        enum Command {
            case start
            case stop
            case retry(count: Int = 1)
        }
        """

    static let ambiguousEnumeration = """
        enum Twice {
            case value
            case value
        }
        """

    static let structureDeclaration = """
        struct Point {
            let x: Int
        }
        """

    static let payloadModelNode = Declaration.Node(
        kind: .enumeration,
        name: Declaration.Node.Name("Command"),
        members: [
            Declaration.Node.Member(name: Declaration.Node.Name("start")),
            Declaration.Node.Member(
                name: Declaration.Node.Name("retry"),
                typeReference: Declaration.Node.Member.TypeReference("Int"),
                label: Declaration.Node.Member.Label("count"),
                defaultValue: Declaration.Node.Member.DefaultValue("1")
            ),
        ]
    )

    static func declaration(_ source: String) -> DeclSyntax {
        let file = Parser.parse(source: source)
        guard let declaration = file.statements.first?.item.as(DeclSyntax.self) else {
            fatalError("fixture does not parse to a declaration")
        }
        return declaration
    }
}
