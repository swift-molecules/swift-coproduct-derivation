// Coproduct.Derivation.MacroPlugin.swift

import CoproductDerivation
import Declaration_Derivation_Model
import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler-plugin entry point of the coproduct derivation package.
///
/// `@main` must attach to a top-level type, so the plugin is the one
/// top-level name of the macros target; the macro it provides is
/// `CoproductMacro`, the resolvable coordinate that forwards to the
/// `Coproduct.Macro` front and implements the `@Coproduct` attached macro.
@main
struct CoproductDerivationMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CoproductMacro.self
    ]
}
