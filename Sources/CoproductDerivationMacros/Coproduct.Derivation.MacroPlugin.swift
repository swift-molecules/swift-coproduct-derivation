// Coproduct.Derivation.MacroPlugin.swift

import CoproductDerivation
import DeclarationDerivationModel
import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler-plugin entry point of the coproduct derivation package.
///
/// `@main` must attach to a top-level type, so the plugin is the one
/// top-level name of the macros target; the macro front it provides is
/// `Coproduct.Macro`, registered as the `@Coproduct` attached macro.
@main
struct CoproductDerivationMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        Coproduct.Macro.self
    ]
}
