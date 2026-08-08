// Coproduct.Macro.swift

/// The attached-macro front of coproduct derivation.
///
/// `@Coproduct` derives, as members of the attached enumeration, the
/// exhaustive `fold` over its alternatives and the provenance member the
/// generation contract mandates; `@Coproduct(prisms: true)` additionally
/// derives one optional-projection property per alternative. Expansion
/// occurs at build time in the consumer through the
/// `CoproductDerivationMacros` compiler plugin; no generated source is
/// placed under version control.
@attached(member, names: named(fold), named(coproductDerivationProvenance), arbitrary)
public macro Coproduct(prisms: Bool = false) =
  #externalMacro(module: "CoproductDerivationMacros", type: "CoproductMacro")
