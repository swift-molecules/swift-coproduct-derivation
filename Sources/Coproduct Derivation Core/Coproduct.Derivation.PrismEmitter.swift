public import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model

extension Coproduct.Derivation {

    public struct PrismEmitter: Sendable {

        public init() {}
    }
}

extension Coproduct.Derivation.PrismEmitter {

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
