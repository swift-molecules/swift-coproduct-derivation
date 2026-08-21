import Coproduct_Derivation_Core
import Declaration_Derivation_Model
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CoproductDerivationMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CoproductMacro.self
    ]
}
