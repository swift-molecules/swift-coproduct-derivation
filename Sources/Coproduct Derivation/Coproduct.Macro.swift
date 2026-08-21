@attached(member, names: named(fold), named(coproductDerivationProvenance), arbitrary)
public macro Coproduct(prisms: Bool = false) =
    #externalMacro(module: "CoproductDerivationMacros", type: "CoproductMacro")
