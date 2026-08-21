import Coproduct_Derivation_Core
import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
public import SwiftSyntax
public import SwiftSyntaxMacros

extension Coproduct {

    public struct Macro: MemberMacro {
    }
}

extension Coproduct.Macro {

    public static let contract = Coproduct.GenerationContract.version1

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws(Declaration.Derivation.Diagnostic) -> [DeclSyntax] {
        let adapter = Declaration.SwiftSyntaxAdapter()
        let intermediateRepresentation = try normalize(
            declaration,
            using: adapter
        )
        let analyzed = try Declaration.Derivation.Analyzer().analyze(
            intermediateRepresentation
        )
        let model = try Coproduct.Derivation.Model(analyzed)
        var members = Coproduct.Derivation.Emitter(contract: Self.contract)
            .memberDeclarations(for: model)
        if emitsPrisms(node) {
            members.append(
                contentsOf: Coproduct.Derivation.PrismEmitter().memberDeclarations(for: model)
            )
        }
        return members.map { member in
            DeclSyntax("\(raw: member)")
        }
    }

    private static func normalize(
        _ declaration: some DeclGroupSyntax,
        using adapter: Declaration.SwiftSyntaxAdapter
    ) throws(Declaration.Derivation.Diagnostic) -> Declaration.IR {
        let intermediateRepresentation = try adapter.intermediateRepresentation(
            from: declaration
        )
        guard let enumeration = declaration.as(EnumDeclSyntax.self) else {
            return intermediateRepresentation
        }

        var members: [Declaration.Node.Member] = []
        for item in enumeration.memberBlock.members {
            guard let enumerationCase = item.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }
            for element in enumerationCase.elements {
                guard let parameters = element.parameterClause?.parameters,
                    !parameters.isEmpty
                else {
                    members.append(
                        Declaration.Node.Member(
                            name: Declaration.Node.Name(element.name.trimmedDescription)
                        )
                    )
                    continue
                }
                guard parameters.count == 1, let parameter = parameters.first else {
                    throw Declaration.Derivation.Diagnostic(
                        code: .malformedDeclaration,
                        subject: intermediateRepresentation.node.name,
                        detail: "coproduct derivation supports one associated value per case"
                    )
                }
                members.append(
                    Declaration.Node.Member(
                        name: Declaration.Node.Name(element.name.trimmedDescription),
                        typeReference: Declaration.Node.Member.TypeReference(
                            parameter.type.trimmedDescription
                        ),
                        label: parameter.firstName.map {
                            Declaration.Node.Member.Label($0.trimmedDescription)
                        },
                        defaultValue: parameter.defaultValue.map {
                            Declaration.Node.Member.DefaultValue($0.value.trimmedDescription)
                        }
                    )
                )
            }
        }
        return Declaration.IR(
            node: Declaration.Node(
                kind: .enumeration,
                name: intermediateRepresentation.node.name,
                members: members
            )
        )
    }

    private static func emitsPrisms(_ node: AttributeSyntax) -> Bool {
        guard case .argumentList(let arguments) = node.arguments else {
            return false
        }
        for argument in arguments where argument.label?.text == "prisms" {
            guard let literal = argument.expression.as(BooleanLiteralExprSyntax.self) else {
                return false
            }
            return literal.literal.tokenKind == .keyword(.true)
        }
        return false
    }
}
