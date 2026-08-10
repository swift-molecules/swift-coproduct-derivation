// CoproductMacro.swift

import Coproduct_Derivation_Core
import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model
public import SwiftSyntax
public import SwiftSyntaxMacros

/// The resolvable implementation coordinate of the `@Coproduct` attached
/// macro.
///
/// The compiler plugin resolves a macro implementation by exact
/// `String(reflecting:)` name, and a type nested in a namespace declared by
/// another module reflects under *that* module. So `Coproduct.Macro` —
/// nested in `Coproduct`, a type of `Coproduct_Derivation_Core` — cannot satisfy a
/// `CoproductDerivationMacros.…` coordinate however it is spelled. This
/// top-level type is that coordinate; it carries no behaviour of its own and
/// forwards every expansion to `Coproduct.Macro`.
public struct CoproductMacro: MemberMacro {
}

extension CoproductMacro {
    /// Expands the attached declaration into its derived members.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws(Declaration.Derivation.Diagnostic) -> [DeclSyntax] {
        try Coproduct.Macro.expansion(
            of: node,
            providingMembersOf: declaration,
            conformingTo: protocols,
            in: context
        )
    }
}
