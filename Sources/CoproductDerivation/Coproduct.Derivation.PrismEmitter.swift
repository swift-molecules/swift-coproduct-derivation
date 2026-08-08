// Coproduct.Derivation.PrismEmitter.swift

public import DeclarationDerivationDiagnostics
public import DeclarationDerivationModel

extension Coproduct.Derivation {
  /// The deterministic emitter of the optional per-case prisms.
  ///
  /// A prism is the optional projection of one alternative: `nil` when the
  /// value inhabits another case, the payload (or `Void` for a payload-free
  /// case) when it matches. Prism emission is opt-in — the `@Coproduct`
  /// front requests it with `prisms: true` — and, like the fold, is a pure
  /// function of the coproduct model: the same input renders
  /// byte-identically on every run. Each derived member is named
  /// `<case>Prism` so it never collides with the case itself or with
  /// handwritten members outside the contract.
  public struct PrismEmitter: Sendable {
    public init() {}
  }
}

extension Coproduct.Derivation.PrismEmitter {

  /// The derived prism declarations for a coproduct model, one per
  /// case, in declaration order.
  public func memberDeclarations(
    for model: Coproduct.Derivation.Model
  ) -> [String] {
    model.cases.map { alternative in
      if let payload = alternative.payloadTypeReference {
        return """
          public var \(alternative.name.text)Prism: (\(payload.text))? {
              guard case .\(alternative.name.text)(let value) = self else {
                  return nil
              }
              return value
          }
          """
      }
      return """
        public var \(alternative.name.text)Prism: Void? {
            guard case .\(alternative.name.text) = self else {
                return nil
            }
            return ()
        }
        """
    }
  }
}
