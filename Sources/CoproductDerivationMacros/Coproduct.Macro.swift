// Coproduct.Macro.swift

import CoproductDerivation
import DeclarationDerivationAnalysis
import DeclarationDerivationDiagnostics
public import DeclarationDerivationModel
import DeclarationSwiftSyntaxAdapter
public import SwiftSyntax
public import SwiftSyntaxMacros

extension Coproduct {
  /// The `@Coproduct` attached-macro front over the coproduct core.
  ///
  /// The macro is a thin adapter: it normalizes the attached declaration
  /// through `Declaration.SwiftSyntaxAdapter`, validates the IR through
  /// `Declaration.Derivation.Analyzer`, views it as a nominal coproduct
  /// through `Coproduct.Derivation.Model` and renders members through
  /// `Coproduct.Derivation.Emitter` — plus, when the attribute requests
  /// `prisms: true`, through `Coproduct.Derivation.PrismEmitter`.
  /// Expansion happens at build time in the consumer; the macro receives
  /// the attached declaration only and performs no input or output of any
  /// other kind. Every expansion carries the generation contract's
  /// provenance (contract revision, IR schema version, package version
  /// pin) as a generated member.
  public struct Macro: MemberMacro {
  }
}

extension Coproduct.Macro {
  /// The generation contract this macro front emits under.
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

  /// Enriches the shared declaration IR with the single associated
  /// value the coproduct model and emitters support.
  ///
  /// The shared SwiftSyntax adapter currently normalizes every enum
  /// case as payload-free. Rebuilding only enumeration members here
  /// keeps the workaround inside the macro boundary that has syntax
  /// access, while all downstream analysis and emission continue to
  /// consume the existing syntax-independent IR.
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

  /// Whether the attribute opts in to prism emission with
  /// `@Coproduct(prisms: true)`.
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
