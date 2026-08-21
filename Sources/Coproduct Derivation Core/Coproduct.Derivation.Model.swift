public import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model

public enum Coproduct {}

extension Coproduct {

    public enum Derivation {}
}

extension Coproduct.Derivation {

    public struct Model: Hashable, Sendable {

        public struct Case: Hashable, Sendable {

            public let name: Declaration.Node.Name

            public let payloadTypeReference: Declaration.Node.Member.TypeReference?

            public let payloadLabel: Declaration.Node.Member.Label?

            public let payloadDefaultValue: Declaration.Node.Member.DefaultValue?

            public init(
                name: Declaration.Node.Name,
                payloadTypeReference: Declaration.Node.Member.TypeReference? = nil,
                payloadLabel: Declaration.Node.Member.Label? = nil,
                payloadDefaultValue: Declaration.Node.Member.DefaultValue? = nil
            ) {
                self.name = name
                self.payloadTypeReference = payloadTypeReference
                self.payloadLabel = payloadLabel
                self.payloadDefaultValue = payloadDefaultValue
            }
        }

        public let name: Declaration.Node.Name

        public let cases: [Case]

        public init(
            _ intermediateRepresentation: Declaration.IR
        ) throws(Declaration.Derivation.Diagnostic) {
            let node = intermediateRepresentation.node
            guard node.kind == .enumeration else {
                throw Declaration.Derivation.Diagnostic(
                    code: .unsupportedDeclarationKind,
                    subject: node.name,
                    detail: "coproduct derivation covers enumerations only"
                )
            }
            self.name = node.name
            self.cases = node.members.map { member in
                Case(
                    name: member.name,
                    payloadTypeReference: member.typeReference,
                    payloadLabel: member.label,
                    payloadDefaultValue: member.defaultValue
                )
            }
        }
    }
}

extension Coproduct {

    public struct GenerationContract: Hashable, Sendable {

        public let revision: Declaration.GenerationContract.Revision

        public let schemaVersion: Declaration.IR.SchemaVersion

        public let packageVersionPin: Declaration.GenerationContract.PackageVersionPin

        public init(
            revision: Declaration.GenerationContract.Revision,
            schemaVersion: Declaration.IR.SchemaVersion,
            packageVersionPin: Declaration.GenerationContract.PackageVersionPin
        ) {
            self.revision = revision
            self.schemaVersion = schemaVersion
            self.packageVersionPin = packageVersionPin
        }
    }
}

extension Coproduct.GenerationContract {

    public static let version1 = Coproduct.GenerationContract(
        revision: Declaration.GenerationContract.Revision("1"),
        schemaVersion: .version1,
        packageVersionPin: Declaration.GenerationContract.PackageVersionPin(
            "swift-primitives/swift-coproduct-derivation@main"
        )
    )

    public static let generatedFileNameSuffix = "+CoproductDerivation.generated.swift"

    public func isGenerated(fileName: String) -> Bool {
        fileName.hasSuffix(Self.generatedFileNameSuffix)
    }

    public var provenance: String {
        "contract-revision=\(revision.text);ir-schema=\(schemaVersion.identifier);package-version-pin=\(packageVersionPin.text)"
    }
}
