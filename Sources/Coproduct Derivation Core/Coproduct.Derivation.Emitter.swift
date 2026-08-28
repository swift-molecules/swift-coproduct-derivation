internal import Declaration_Derivation_Model

extension Coproduct.Derivation {

    public struct Emitter: Sendable {

        public let contract: Coproduct.GenerationContract

        public init(contract: Coproduct.GenerationContract) {
            self.contract = contract
        }
    }
}

extension Coproduct.Derivation.Emitter {

    public func memberDeclarations(
        for model: Coproduct.Derivation.Model
    ) -> [String] {
        [fold(for: model), provenanceMember()]
    }

    private func fold(for model: Coproduct.Derivation.Model) -> String {
        if model.cases.isEmpty {
            return """
                public func fold<Result>() -> Result {
                    switch self {
                    }
                }
                """
        }
        var parameters: [String] = []
        var arms: [String] = []
        for alternative in model.cases {
            if let payload = alternative.payloadTypeReference {
                parameters.append("\(alternative.name.text): (\(payload.text)) -> Result")
                arms.append("    case .\(alternative.name.text)(let value):")
                arms.append("        \(alternative.name.text)(value)")
            } else {
                parameters.append("\(alternative.name.text): () -> Result")
                arms.append("    case .\(alternative.name.text):")
                arms.append("        \(alternative.name.text)()")
            }
        }
        var lines: [String] = ["public func fold<Result>("]
        lines.append(parameters.map { "    \($0)" }.joined(separator: ",\n"))
        lines.append(") -> Result {")
        lines.append("    switch self {")
        lines.append(contentsOf: arms)
        lines.append("    }")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func provenanceMember() -> String {
        "public static var coproductDerivationProvenance: String { \"\(contract.provenance)\" }"
    }
}
