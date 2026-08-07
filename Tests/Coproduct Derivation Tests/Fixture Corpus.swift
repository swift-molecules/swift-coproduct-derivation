// Fixture Corpus.swift

import DeclarationDerivationModel
import SwiftParser
import SwiftSyntax

/// The TX-D2 fixture corpus: the enumeration forms coproduct derivation must
/// cover — zero-member, single-member and label/default-preserving — plus
/// the malformed and non-coproduct negatives.
enum FixtureCorpus {
}

extension FixtureCorpus {
    /// Zero-member (uninhabited) enumeration.
    static let zeroCaseEnumeration = "enum Impossible {}"

    /// Single-member enumeration.
    static let singleCaseEnumeration = """
        enum Unit {
            case only
        }
        """

    /// Multi-case enumeration, including a payload case whose label and
    /// default spellings the source declares and the model must preserve.
    static let labelPreservingEnumeration = """
        enum Command {
            case start
            case stop
            case retry(count: Int = 1)
        }
        """

    /// Duplicate case names make ownership of the derived interface
    /// ambiguous.
    static let ambiguousEnumeration = """
        enum Twice {
            case value
            case value
        }
        """

    /// A structure is a product, not a coproduct.
    static let structureDeclaration = """
        struct Point {
            let x: Int
        }
        """

    /// The payload-carrying coproduct model exercised without syntax: a
    /// labeled, defaulted `Int` payload on `retry`, preserved verbatim.
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

    /// The first declaration parsed from a fixture source.
    static func declaration(_ source: String) -> DeclSyntax {
        let file = Parser.parse(source: source)
        guard let declaration = file.statements.first?.item.as(DeclSyntax.self) else {
            fatalError("fixture does not parse to a declaration")
        }
        return declaration
    }}
